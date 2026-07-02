import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timer_grobi/core/hijri_calibration.dart';
import 'package:timer_grobi/models/islamic_event.dart';

void main() {
  // ما تتوقّعه الحزمة لبداية رمضان 1447 — مرجع نبني حوله الحالات.
  final pkgRamadan = HijriCalendar().hijriToGregorian(1447, 9, 1);

  EventAnnouncement ann(DateTime g,
          {int year = 1447, IslamicEventType type = IslamicEventType.ramadan}) =>
      EventAnnouncement(type: type, hijriYear: year, gregorianDate: g);

  group('suggestedHijriAdjust', () {
    test('تطابق التاريخ الرسمي مع الحزمة ⇒ 0', () {
      expect(suggestedHijriAdjust(ann(pkgRamadan)), 0);
    });

    test('الرسمي قبل توقّع الحزمة بيوم ⇒ +1', () {
      expect(
          suggestedHijriAdjust(
              ann(pkgRamadan.subtract(const Duration(days: 1)))),
          1);
    });

    test('الرسمي بعد توقّع الحزمة بيوم ⇒ -1', () {
      expect(suggestedHijriAdjust(ann(pkgRamadan.add(const Duration(days: 1)))),
          -1);
    });

    test('سنة هجرية غير صالحة ⇒ null', () {
      expect(suggestedHijriAdjust(ann(pkgRamadan, year: 0)), isNull);
    });
  });

  group('pickPendingSuggestion', () {
    bool always(DateTime d, DateTime n) => true;
    final now = pkgRamadan;

    test('إزاحة مختلفة غير مُعالَجة ضمن الصلة ⇒ تُرجَع', () {
      final a = ann(pkgRamadan.subtract(const Duration(days: 1))); // +1
      final s = pickPendingSuggestion(
          stored: [a],
          currentAdjust: 0,
          handledKeys: const {},
          now: now,
          isRelevant: always);
      expect(s, isNotNull);
      expect(s!.suggestedAdjust, 1);
      expect(s.handledKey, '${a.key}:1');
    });

    test('مفتاح مُعالَج ⇒ null', () {
      final a = ann(pkgRamadan.subtract(const Duration(days: 1)));
      final s = pickPendingSuggestion(
          stored: [a],
          currentAdjust: 0,
          handledKeys: {'${a.key}:1'},
          now: now,
          isRelevant: always);
      expect(s, isNull);
    });

    test('الاقتراح يساوي التعديل الحالي ⇒ null', () {
      final s = pickPendingSuggestion(
          stored: [ann(pkgRamadan)], // 0
          currentAdjust: 0,
          handledKeys: const {},
          now: now,
          isRelevant: always);
      expect(s, isNull);
    });

    test('خارج نافذة الصلة ⇒ null', () {
      final a = ann(pkgRamadan.subtract(const Duration(days: 1)));
      final s = pickPendingSuggestion(
          stored: [a],
          currentAdjust: 0,
          handledKeys: const {},
          now: now,
          isRelevant: (d, n) => false);
      expect(s, isNull);
    });
  });
}
