import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/models/islamic_event.dart';
import 'package:timer_grobi/providers/announcements_provider.dart';
import 'package:timer_grobi/services/announcements_store.dart';
import 'package:timer_grobi/services/fcm_service.dart';
import 'package:timer_grobi/services/notification_service.dart';

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

  group('التثبيت الصامت وشعبان', () {
    test('صفّ خادم بلا event_type وشهره صالح ⇒ تثبيت صامت', () {
      final a = EventAnnouncement.fromServer({
        'event_type': null,
        'hijri_month': 5,
        'hijri_year': 1448,
        'gregorian_date': '2026-10-11',
        'note': null,
      });
      expect(a, isNotNull);
      expect(a!.isSilent, isTrue);
      expect(a.hijriMonth, 5);
      expect(a.key, 'm5_1448');
    });

    test('نوع أحدث من هذه النسخة مع شهر صالح ⇒ يُقبل تثبيتاً صامتاً', () {
      final a = EventAnnouncement.fromServer({
        'event_type': 'mawlid',
        'hijri_month': 3,
        'hijri_year': 1448,
        'gregorian_date': '2026-08-14',
      });
      expect(a?.isSilent, isTrue);
      expect(a?.hijriMonth, 3);
    });

    test('بلا نوع ولا شهر صالح ⇒ null', () {
      expect(
          EventAnnouncement.fromServer({
            'event_type': null,
            'hijri_month': 13,
            'hijri_year': 1448,
            'gregorian_date': '2026-10-11',
          }),
          isNull);
    });

    test('شعبان مناسبة مسمّاة للشهر 8', () {
      final a = EventAnnouncement.fromServer({
        'event_type': 'shaban',
        'hijri_month': 8,
        'hijri_year': 1448,
        'gregorian_date': '2027-01-09',
      });
      expect(a?.type, IslamicEventType.shaban);
      expect(a?.hijriMonth, 8);
      expect(a?.key, 'shaban_1448');
    });

    test('النوع المعروف هو مرجع الشهر (المفتاح القديم نوع_سنة يبقى)', () {
      final a = EventAnnouncement.fromServer({
        'event_type': 'ramadan',
        'hijri_month': '9',
        'hijri_year': '1447',
        'gregorian_date': '2026-02-18',
      });
      expect(a?.hijriMonth, 9);
      expect(a?.key, 'ramadan_1447');
    });

    test('حمولة FCM صامتة (بلا type) تُقرأ من hijri_month', () {
      final a = EventAnnouncement.fromPushData({
        'hijri_month': '6',
        'hijri_year': '1448',
        'gregorian_date': '2026-11-10',
        'country': 'eg',
      });
      expect(a?.isSilent, isTrue);
      expect(a?.hijriMonth, 6);
    });

    test('مخزَّن بصيغة قديمة (بلا hijriMonth) يُقرأ', () {
      final a = EventAnnouncement.fromJson({
        'type': 'eid_fitr',
        'hijriYear': 1447,
        'gregorianDate': '2026-03-20T00:00:00.000',
        'note': null,
      });
      expect(a?.hijriMonth, 10);
      final silent = EventAnnouncement(
          hijriYear: 1448, hijriMonth: 5, gregorianDate: DateTime(2026, 10, 11));
      final round = EventAnnouncement.fromJson(silent.toJson());
      expect(round?.key, silent.key);
      expect(round?.isSilent, isTrue);
    });
  });

  group('عدم التكرار', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          'settings.countryCode': 'sa',
        }));

    test('إعلان Push يُعلَّم منبَّهاً لحظة وصوله فلا تُعيده المزامنة', () async {
      final data = {
        'type': 'ramadan',
        'hijri_month': '9',
        'hijri_year': '1448',
        'gregorian_date': '2027-02-08',
        'country': 'sa',
      };
      final ann = await FcmService.ingestAnnouncementData(data);
      expect(ann?.key, 'ramadan_1448');

      final store = AnnouncementsStore();
      expect((await store.load()).map((a) => a.key), contains('ramadan_1448'));
      final notified = await store.notifiedKeys();
      final fromServer = [
        EventAnnouncement.fromServer({
          'event_type': 'ramadan',
          'hijri_month': 9,
          'hijri_year': 1448,
          'gregorian_date': '2027-02-08',
        })!,
      ];
      expect(newToNotify(fromServer, notified), isEmpty);
    });

    test('التثبيت الصامت يُخزَّن ويُعلَّم ولا يُحسب إعلاناً مسمّى', () async {
      final ann = await FcmService.ingestAnnouncementData({
        'hijri_month': '5',
        'hijri_year': '1448',
        'gregorian_date': '2026-10-11',
        'country': 'sa',
      });
      expect(ann?.isSilent, isTrue);
      expect(await AnnouncementsStore().notifiedKeys(), contains('m5_1448'));
    });

    test('إعلان دولة أخرى يُتجاهل، والبثّ الحرّ ليس إعلاناً', () async {
      expect(
          await FcmService.ingestAnnouncementData({
            'type': 'ramadan',
            'hijri_year': '1448',
            'gregorian_date': '2027-02-08',
            'country': 'eg',
          }),
          isNull);
      expect(await FcmService.ingestAnnouncementData({'msg': 'hello'}), isNull);
      expect(await AnnouncementsStore().load(), isEmpty);
    });

    test('رسالة تجريبية (test=1) تُخزَّن ولا تُعلَّم منبَّهاً', () async {
      final ann = await FcmService.ingestAnnouncementData({
        'type': 'ramadan',
        'hijri_month': '9',
        'hijri_year': '1448',
        'gregorian_date': '2027-02-08',
        'country': 'sa',
        'test': '1',
      });
      expect(ann?.key, 'ramadan_1448');
      expect((await AnnouncementsStore().load()).map((a) => a.key),
          contains('ramadan_1448'));
      expect(await AnnouncementsStore().notifiedKeys(),
          isNot(contains('ramadan_1448')));
    });

    test('معرّف التنبيه ثابت للمفتاح نفسه ومختلف لغيره', () {
      expect(NotificationService.idFor('ramadan_1448'),
          NotificationService.idFor('ramadan_1448'));
      expect(NotificationService.idFor('ramadan_1448'),
          isNot(NotificationService.idFor('eid_fitr_1448')));
      // FNV-1a ثابت عبر العزلات والتشغيلات (لا يعتمد على hashCode).
      expect(NotificationService.idFor(''), 0x811c9dc5 & 0x7fffffff);
      expect(NotificationService.idFor('ramadan_1448'),
          inInclusiveRange(0, 0x7fffffff));
    });
  });

  group('النشر الصامت (notify)', () {
    test('notify=0 من الخادم أو FCM ⇒ لا تنبيه عند المزامنة', () {
      final now = DateTime(2027, 2, 8);
      final silentNamed = EventAnnouncement.fromServer({
        'event_type': 'ramadan',
        'hijri_month': 9,
        'hijri_year': 1448,
        'gregorian_date': '2027-02-08',
        'notify': 0,
      })!;
      expect(silentNamed.notify, isFalse);
      expect(shouldNotifyOnSync(silentNamed, now), isFalse);

      final visible = EventAnnouncement.fromServer({
        'event_type': 'ramadan',
        'hijri_month': 9,
        'hijri_year': 1448,
        'gregorian_date': '2027-02-08',
        'notify': 1,
      })!;
      expect(shouldNotifyOnSync(visible, now), isTrue);

      expect(
          EventAnnouncement.fromPushData({
            'type': 'ramadan',
            'hijri_year': '1448',
            'gregorian_date': '2027-02-08',
            'notify': '0',
          })!
              .notify,
          isFalse);
    });

    test('خادم أقدم بلا notify ⇒ يُعدّ مرئياً، والحقل يُحفظ ويُستعاد', () {
      final old = EventAnnouncement.fromServer({
        'event_type': 'eid_fitr',
        'hijri_year': 1448,
        'gregorian_date': '2027-03-10',
      })!;
      expect(old.notify, isTrue);
      final silent = EventAnnouncement(
          type: IslamicEventType.shaban,
          hijriYear: 1448,
          gregorianDate: DateTime(2027, 1, 9),
          notify: false);
      expect(EventAnnouncement.fromJson(silent.toJson())!.notify, isFalse);
    });

    test('التثبيت الصامت بلا نوع لا ينبّه أبداً', () {
      final a = EventAnnouncement(
          hijriYear: 1448, hijriMonth: 5, gregorianDate: DateTime(2026, 10, 11));
      expect(shouldNotifyOnSync(a, DateTime(2026, 10, 11)), isFalse);
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
