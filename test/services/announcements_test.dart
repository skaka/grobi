import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/models/islamic_event.dart';
import 'package:timer_grobi/providers/announcements_provider.dart';
import 'package:timer_grobi/services/announcements_store.dart';

EventAnnouncement _ann(IslamicEventType type) => EventAnnouncement(
      type: type,
      hijriYear: 1447,
      gregorianDate: DateTime(2026, 2, 18),
    );

void main() {
  group('EventAnnouncement', () {
    test('تحليل استجابة الخادم', () {
      final a = EventAnnouncement.fromServer({
        'event_type': 'ramadan',
        'hijri_year': 1447,
        'gregorian_date': '2026-02-18',
        'note': null,
      });
      expect(a, isNotNull);
      expect(a!.type, IslamicEventType.ramadan);
      expect(a.hijriYear, 1447);
      expect(a.gregorianDate, DateTime(2026, 2, 18));
      expect(a.key, 'ramadan_1447');
    });

    test('نوع غير معروف ⇒ null', () {
      final a = EventAnnouncement.fromServer({
        'event_type': 'unknown',
        'hijri_year': 1447,
        'gregorian_date': '2026-02-18',
      });
      expect(a, isNull);
    });

    test('تسلسل ذهاب/عودة JSON', () {
      final orig = _ann(IslamicEventType.eidFitr);
      final round = EventAnnouncement.fromJson(orig.toJson());
      expect(round, isNotNull);
      expect(round!.type, IslamicEventType.eidFitr);
      expect(round.key, orig.key);
      expect(round.gregorianDate, orig.gregorianDate);
    });
  });

  group('منطق التنبيه', () {
    final base = [_ann(IslamicEventType.ramadan), _ann(IslamicEventType.eidFitr)];

    test('newToNotify يُرجِع غير المُنبَّه عنه فقط', () {
      final fresh = newToNotify(base, {'ramadan_1447'});
      expect(fresh.length, 1);
      expect(fresh.first.type, IslamicEventType.eidFitr);
    });

    test('نافذة الأهمية: اليوم/−3/+45 داخل، −4/+46 خارج', () {
      final now = DateTime(2026, 3, 1);
      expect(relevantForNotification(DateTime(2026, 3, 1), now), isTrue);
      expect(relevantForNotification(DateTime(2026, 2, 26), now), isTrue); // -3
      expect(relevantForNotification(DateTime(2026, 2, 25), now), isFalse); // -4
      expect(relevantForNotification(DateTime(2026, 4, 15), now), isTrue); // +45
      expect(relevantForNotification(DateTime(2026, 4, 16), now), isFalse); // +46
    });
  });
}
