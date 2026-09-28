import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_utils.dart';
import '../core/format_utils.dart';
import '../core/umm_alqura_corrections.dart';
import '../l10n/l10n.dart';
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
  final d = daysBetween(now, eventDate);
  return d >= -3 && d <= 45;
}

/// هل تُظهر المزامنة تنبيهاً لإعلانٍ جديد؟ فقط لمناسبة مسمّاة لم يُنشر صامتاً،
/// ضمن نافذة الأهمية.
bool shouldNotifyOnSync(EventAnnouncement a, DateTime now) =>
    a.type != null && a.notify && relevantForNotification(a.gregorianDate, now);

class AnnouncementsNotifier extends AsyncNotifier<List<EventAnnouncement>> {
  final AnnouncementsStore _store = AnnouncementsStore();

  @override
  Future<List<EventAnnouncement>> build() => _store.load();

  /// يعيد قراءة المخزَّن (بعد عودة التطبيق من الخلفية): معالج FCM الخلفي يعمل في
  /// عزلة مستقلة، فما خزّنه من تثبيتات لا يصل الواجهة إلا بإعادة القراءة.
  Future<void> reloadFromStore() async {
    state = AsyncData(await _store.load());
  }

  /// عند تغيير الدولة: تُمسح تثبيتات الدولة السابقة (لا تخصّ تقويم الجديدة) ثم
  /// تُجلب إعلانات الجديدة.
  Future<SyncResult> switchCountry() async {
    await _store.clear();
    state = const AsyncData([]);
    return syncNow();
  }

  /// يجلب إعلانات الدولة، يخزّنها، ويُظهر تنبيهاً للجديد المسمّى ضمن نافذة الأهمية.
  /// التثبيتات الصامتة تُخزَّن وتصحّح التقويم دون تنبيه.
  Future<SyncResult> syncNow() async {
    final s = ref.read(settingsProvider);
    if (s.countryCode == null) {
      return SyncResult(false, tr.syncPickCountry, 0);
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
        final type = a.type;
        if (type != null && shouldNotifyOnSync(a, now)) {
          await NotificationService.show(
            NotificationService.idFor(a.key),
            eventName(type),
            eventNotificationBody(type),
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
      for (final issue in buildAnchoring(incoming).issues) {
        await DiagLog.add('anchor', issue);
      }
      return SyncResult(
        true,
        shown > 0
            ? tr.syncNewAlerts(localDigits('$shown'))
            : tr.syncNothingNew,
        shown,
      );
    } catch (e) {
      await DiagLog.add('sync', 'تعذّرت المزامنة: $e');
      return SyncResult(false, tr.syncFailed('$e'), 0);
    }
  }

}

final announcementsProvider =
    AsyncNotifierProvider<AnnouncementsNotifier, List<EventAnnouncement>>(
  AnnouncementsNotifier.new,
);
