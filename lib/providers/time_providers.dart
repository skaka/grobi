import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/date_utils.dart';
import '../core/ghuroubi_date.dart';
import '../core/prayer_service.dart';
import '../core/solar_time.dart';
import '../core/umm_alqura_corrections.dart';
import '../models/day_times.dart';
import '../models/ghuroubi_now.dart';
import 'announcements_provider.dart';
import 'location_provider.dart';
import 'settings_provider.dart';

/// نبضة كل ثانية — **للعدّادات التنازلية فقط**. تتوقّف عند تصغير التطبيق عبر
/// [SecondTicker.pause] (يُستدعى من دورة حياة `MainShell`) توفيراً للبطارية.
class SecondTicker extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    _start();
    return DateTime.now();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => state = DateTime.now());
  }

  void pause() => _timer?.cancel();

  void resume() {
    state = DateTime.now();
    _start();
  }
}

final secondTickerProvider =
    NotifierProvider<SecondTicker, DateTime>(SecondTicker.new);

/// نبضة عند **حدود كل دقيقة** — لكل ما حبيبته الدقيقة (وجه الساعة، التواريخ،
/// التوقيت الزوالي، مواقيت الصلاة). موقوتة على بداية الدقيقة كي تنقلب الساعة في
/// لحظتها الصحيحة، وتتوقّف في الخلفية كـ[SecondTicker].
class MinuteTicker extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    _schedule();
    return DateTime.now();
  }

  void _schedule() {
    _timer = Timer(
        Duration(milliseconds: millisUntilNextMinute(DateTime.now())), () {
      state = DateTime.now();
      _schedule();
    });
  }

  void pause() => _timer?.cancel();

  void resume() {
    state = DateTime.now();
    _timer?.cancel();
    _schedule();
  }
}

/// المللي ثانية حتى بداية الدقيقة التالية (1..60000)، محسوبةً من الزمن المطلق:
/// بناؤها من حقول الساعة المحلية يعطي انتظاراً سالباً في الساعة المكرّرة عند تأخير
/// التوقيت الصيفي، فيدور المؤقّت بلا توقّف ساعةً كاملة. (فروق المناطق الزمنية
/// دقائق كاملة، فحدود الدقيقة واحدة محلياً وعالمياً.)
int millisUntilNextMinute(DateTime now) =>
    60000 - now.millisecondsSinceEpoch % 60000;

final minuteTickerProvider =
    NotifierProvider<MinuteTicker, DateTime>(MinuteTicker.new);

/// خريطة تصحيحات جدول أم القرى المشتقّة من الإعلانات المخزّنة — المرجع الموحّد
/// للتاريخ الهجري في كل التطبيق (الساعة + التقويم + كشف رمضان).
final hijriAdjustmentsProvider = Provider.autoDispose<Map<int, int>>((ref) {
  final anns = ref.watch(announcementsProvider).valueOrNull ?? const [];
  ref.keepAlive();
  return adjustmentsFromAnnouncements(anns);
});

/// يُبقي الحساب مخزّناً ما دام مُراقَباً، ثم [linger] بعد آخر مراقب فيُحرَّر — بدل
/// `keepAlive()` الدائم الذي كان يُراكم يوماً جديداً كل يوم وكل خلية تقويم تُفتح.
void _cacheWhileUsed(Ref<Object?> ref,
    {Duration linger = const Duration(minutes: 5)}) {
  final link = ref.keepAlive();
  Timer? timer;
  ref.onCancel(() => timer = Timer(linger, link.close));
  ref.onResume(() => timer?.cancel());
  ref.onDispose(() => timer?.cancel());
}

/// مواقيت يوم معيّن. المفتاح تاريخ بلا وقت ([dateOnly]/[addDays]) كي لا ينقسم
/// التخزين بين مفاتيح تختلف بساعة التوقيت الصيفي.
final prayerDayProvider =
    Provider.autoDispose.family<DayTimes, DateTime>((ref, date) {
  final loc = ref.watch(locationProvider);
  final settings = ref.watch(settingsProvider);
  final adjustments = ref.watch(hijriAdjustmentsProvider);
  _cacheWhileUsed(ref);
  return computeDayTimes(loc, dateOnly(date), settings.method,
      hijriAdjust: settings.hijriAdjust,
      adjustments: adjustments,
      horizonHeight: settings.horizonHeight);
});

/// التاريخ الهجري الغروبي مخزَّن بمفتاح (التاريخ الميلادي الغروبي) — يُحسب مرة
/// في اليوم بدل كل دقيقة. يتبدّل عند تغيّر التصحيحات (الإعلانات) أو `hijriAdjust`.
final ghuroubiHijriProvider =
    Provider.autoDispose.family<HijriCalendar, DateTime>((ref, civilDate) {
  final adjust = ref.watch(settingsProvider.select((s) => s.hijriAdjust));
  final adjustments = ref.watch(hijriAdjustmentsProvider);
  _cacheWhileUsed(ref);
  return correctedHijri(civilDate, adjustments, manualAdjust: adjust);
});

/// اللقطة الغروبية الحالية (تُحدَّث كل **دقيقة**). العدّادات التنازلية بالثواني
/// تُحسب في widgets صغيرة تراقب [secondTickerProvider] اعتماداً على [GhuroubiNow.nextSunset].
final ghuroubiNowProvider = Provider.autoDispose<GhuroubiNow>((ref) {
  final now = ref.watch(minuteTickerProvider);
  final day = ghuroubiDayAt(now, (date) => ref.watch(prayerDayProvider(date)));
  final hijri = ref.watch(ghuroubiHijriProvider(day.civilDate));
  final solar = solarTime(now, ref.watch(locationProvider).longitude);

  return GhuroubiNow(
    now: now,
    clock: day.clock,
    ghuroubiCivilDate: day.civilDate,
    hijri: hijri,
    solar: solar,
    today: day.today,
    nextSunset: day.nextSunset,
  );
});
