import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/ghuroubi_clock.dart';
import '../core/ghuroubi_date.dart';
import '../core/prayer_service.dart';
import '../core/solar_time.dart';
import '../core/umm_alqura_corrections.dart';
import '../models/day_times.dart';
import '../models/ghuroubi_now.dart';
import '../models/location_data.dart';
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
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(const Duration(minutes: 1));
    _timer = Timer(next.difference(now), () {
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

final minuteTickerProvider =
    NotifierProvider<MinuteTicker, DateTime>(MinuteTicker.new);

/// مفتاح اليوم (بلا وقت) لتثبيت تخزين [prayerDayProvider].
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// خريطة تصحيحات جدول أم القرى المشتقّة من الإعلانات المخزّنة — المرجع الموحّد
/// للتاريخ الهجري في كل التطبيق (الساعة + التقويم + كشف رمضان).
final hijriAdjustmentsProvider = Provider.autoDispose<Map<int, int>>((ref) {
  final anns = ref.watch(announcementsProvider).valueOrNull ?? const [];
  ref.keepAlive();
  return adjustmentsFromAnnouncements(anns);
});

/// مواقيت يوم معيّن (مع تصحيح الارتفاع وتجاوز الارتفاع اليدوي).
final prayerDayProvider =
    Provider.autoDispose.family<DayTimes, DateTime>((ref, date) {
  final loc0 = ref.watch(locationProvider);
  final settings = ref.watch(settingsProvider);
  final adjustments = ref.watch(hijriAdjustmentsProvider);
  final LocationData loc = settings.manualAltitude != null
      ? loc0.copyWith(altitude: settings.manualAltitude)
      : loc0;
  ref.keepAlive(); // احتفظ بالحساب ما دام اليوم مرجوعاً
  return computeDayTimes(loc, dateOnly(date), settings.method,
      hijriAdjust: settings.hijriAdjust, adjustments: adjustments);
});

/// التاريخ الهجري الغروبي مخزَّن بمفتاح (التاريخ الميلادي الغروبي) — يُحسب مرة
/// في اليوم بدل كل دقيقة. يتبدّل عند تغيّر التصحيحات (الإعلانات) أو `hijriAdjust`.
final ghuroubiHijriProvider =
    Provider.autoDispose.family<HijriCalendar, DateTime>((ref, civilDate) {
  final adjust = ref.watch(settingsProvider.select((s) => s.hijriAdjust));
  final adjustments = ref.watch(hijriAdjustmentsProvider);
  ref.keepAlive();
  return correctedHijri(civilDate, adjustments, manualAdjust: adjust);
});

/// اللقطة الغروبية الحالية (تُحدَّث كل **دقيقة**). العدّادات التنازلية بالثواني
/// تُحسب في widgets صغيرة تراقب [secondTickerProvider] اعتماداً على [GhuroubiNow.nextSunset].
final ghuroubiNowProvider = Provider.autoDispose<GhuroubiNow>((ref) {
  final now = ref.watch(minuteTickerProvider);
  final today0 = dateOnly(now);

  final yesterday =
      ref.watch(prayerDayProvider(today0.subtract(const Duration(days: 1))));
  final today = ref.watch(prayerDayProvider(today0));
  final tomorrow =
      ref.watch(prayerDayProvider(today0.add(const Duration(days: 1))));

  final clock = GhuroubiClock.at(
    now: now,
    yesterdayMaghrib: yesterday.maghrib,
    todaySunrise: today.sunrise,
    todayMaghrib: today.maghrib,
    tomorrowMaghrib: tomorrow.maghrib,
  );

  final nextSunset =
      now.isBefore(today.maghrib) ? today.maghrib : tomorrow.maghrib;

  final civil = ghuroubiCivilDate(now, today.maghrib);
  final hijri = ref.watch(ghuroubiHijriProvider(civil));
  final solar = solarTime(now, ref.watch(locationProvider).longitude);

  return GhuroubiNow(
    now: now,
    clock: clock,
    ghuroubiCivilDate: civil,
    hijri: hijri,
    solar: solar,
    today: today,
    nextSunset: nextSunset,
  );
});
