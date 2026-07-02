import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/hijri_calibration.dart';
import '../models/islamic_event.dart';
import '../services/announcements_api.dart';
import '../services/announcements_store.dart';
import '../services/diag_log.dart';
import '../services/notification_service.dart';
import 'settings_provider.dart';

class SyncResult {
  final bool ok;
  final String message;
  final int shown;

  const SyncResult(this.ok, this.message, this.shown);
}

/// نافذة الأهمية للتنبيه: من 3 أيام مضت إلى 45 يوماً قادمة.
bool relevantForNotification(DateTime eventDate, DateTime now) {
  final d = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  return d >= -3 && d <= 45;
}

class AnnouncementsNotifier extends AsyncNotifier<List<EventAnnouncement>> {
  final AnnouncementsStore _store = AnnouncementsStore();

  @override
  Future<List<EventAnnouncement>> build() => _store.load();

  /// يجلب إعلانات الدولة، يخزّنها، ويُظهر تنبيهاً للجديد ضمن نافذة الأهمية.
  /// (يُسكِت الإعلانات القديمة عند أول مزامنة لتفادي الإزعاج.)
  Future<SyncResult> syncNow() async {
    final s = ref.read(settingsProvider);
    if (s.countryCode == null) {
      return const SyncResult(false, 'حدّد الدولة أولاً', 0);
    }
    try {
      final api = AnnouncementsApi(kAnnouncementsBaseUrl);
      final incoming = await api.fetch(s.countryCode!);
      await _store.saveAll(incoming);

      final notified = await _store.notifiedKeys();
      final fresh = newToNotify(incoming, notified);

      final now = DateTime.now();
      var shown = 0;
      for (final a in fresh) {
        if (relevantForNotification(a.gregorianDate, now)) {
          await NotificationService.show(
            a.key.hashCode & 0x7fffffff,
            a.type.arabicName,
            _body(a),
          );
          shown++;
        }
      }
      if (fresh.isNotEmpty) {
        await _store.markNotified(fresh.map((e) => e.key)); // baseline
      }

      state = AsyncData(incoming);
      await DiagLog.add('sync',
          'نجحت المزامنة (${s.countryCode}) — ${incoming.length} إعلان، تنبيهات جديدة: $shown');
      return SyncResult(
        true,
        shown > 0 ? 'تنبيهات جديدة: $shown' : 'تمت المزامنة — لا جديد',
        shown,
      );
    } catch (e) {
      await DiagLog.add('sync', 'تعذّرت المزامنة: $e');
      return SyncResult(false, 'تعذّرت المزامنة: $e', 0);
    }
  }

  /// يطبّق اقتراح معايرة التقويم: يضبط التعديل، ويعلّمه كمُعالَج، ويسجّل.
  /// [auto] يفعّل «التصحيح التلقائي مستقبلاً».
  Future<void> applyCalibration(CalibrationSuggestion s,
      {bool auto = false}) async {
    final settings = ref.read(settingsProvider.notifier);
    settings.setHijriAdjust(s.suggestedAdjust);
    if (auto) settings.setAutoCalibrate(true);
    await _store.markCalibrationHandled(s.handledKey);
    ref.invalidate(calibrationHandledProvider);
    await DiagLog.add(
      'calibrate',
      'طُبّق تعديل التقويم ${s.currentAdjust}→${s.suggestedAdjust} '
          '(${s.announcement.type.id})${auto ? ' [تلقائي مفعّل]' : ''}',
    );
  }

  /// يتجاهل اقتراح المعايرة (يعلّمه كمُعالَج فلا يُسأل عنه ثانيةً).
  Future<void> dismissCalibration(CalibrationSuggestion s) async {
    await _store.markCalibrationHandled(s.handledKey);
    ref.invalidate(calibrationHandledProvider);
    await DiagLog.add('calibrate',
        'تُجوهِل تعديل التقويم ${s.currentAdjust}→${s.suggestedAdjust} (${s.announcement.type.id})');
  }

  String _body(EventAnnouncement a) {
    switch (a.type) {
      case IslamicEventType.hijriNewYear:
        return 'ثبتت غُرّة محرّم — كل عام وأنتم بخير.';
      case IslamicEventType.ramadan:
        return 'ثبت دخول شهر رمضان المبارك — رمضان كريم.';
      case IslamicEventType.eidFitr:
        return 'ثبت شوّال وعيد الفطر — عيد مبارك.';
      case IslamicEventType.dhulHijjah:
        return 'دخل شهر ذي الحجة — عرفة وعيد الأضحى قريباً.';
    }
  }
}

final announcementsProvider =
    AsyncNotifierProvider<AnnouncementsNotifier, List<EventAnnouncement>>(
  AnnouncementsNotifier.new,
);

/// مفاتيح اقتراحات المعايرة المُعالَجة (يُبطَل بعد كل تطبيق/تجاهل).
final calibrationHandledProvider = FutureProvider<Set<String>>((ref) async {
  return AnnouncementsStore().calibrationHandledKeys();
});

/// معطّل: صار تثبيت الأشهر من الإعلانات (عبر جدول أم القرى في [hijriAdjustmentsProvider])
/// يصحّح التقويم مباشرةً وعلى مستوى التطبيق كله، فأُلغيت المعايرة العامة (±يوم) هنا
/// لتفادي التصحيح المزدوج. تبقى منطق [pickPendingSuggestion] وإزاحة `hijriAdjust`
/// اليدوية متاحين كاحتياطي.
final pendingCalibrationProvider =
    Provider<CalibrationSuggestion?>((ref) => null);
