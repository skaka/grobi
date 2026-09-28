import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/prayer_service.dart';
import 'package:timer_grobi/models/location_data.dart';

void main() {
  const riyadh = LocationData(latitude: 24.7136, longitude: 46.6753);
  const mecca = LocationData(latitude: 21.4225, longitude: 39.8262);
  const jeddah = LocationData(latitude: 21.4858, longitude: 39.1925);
  const method = CalculationMethod.umm_al_qura;

  PrayerTimes adhanTimes(LocationData loc, DateTime date) => PrayerTimes(
      Coordinates(loc.latitude, loc.longitude),
      DateComponents.from(date),
      method.getParameters());

  group('الافتراضي = أم القرى بلا تصحيح ارتفاع (يطابق adhan حرفياً)', () {
    // أيام خارج رمضان عبر السنة (رمضان يضيف 30 دقيقة للعشاء — مختبَر أدناه).
    final dates = [
      DateTime(2026, 1, 15),
      DateTime(2026, 2, 10), // قبل رمضان 1447 (يبدأ 2026-02-18)
      DateTime(2026, 5, 1),
      DateTime(2026, 6, 21),
      DateTime(2026, 9, 27),
      DateTime(2026, 12, 21),
    ];
    for (final entry in {'الرياض': riyadh, 'مكة': mecca, 'جدة': jeddah}.entries) {
      test(entry.key, () {
        for (final date in dates) {
          final ours = computeDayTimes(entry.value, date, method);
          final ref = adhanTimes(entry.value, date);
          expect(ours.fajr, ref.fajr, reason: '$date');
          expect(ours.sunrise, ref.sunrise, reason: '$date');
          expect(ours.dhuhr, ref.dhuhr, reason: '$date');
          expect(ours.asr, ref.asr, reason: '$date');
          expect(ours.maghrib, ref.maghrib, reason: '$date');
          expect(ours.isha, ref.isha, reason: '$date');
          // adhan يُخرج دقائق كاملة، فلا ثوانٍ تسبق الوقت المحسوب.
          expect(ours.maghrib.second, 0);
        }
      });
    }

    test('مثال الخطة: مغرب الرياض 2026-02-18 = adhan (كان +3:52 بارتفاع GPS)', () {
      final date = DateTime(2026, 2, 18);
      final ours = computeDayTimes(riyadh, date, method);
      final ref = adhanTimes(riyadh, date);
      expect(ours.maghrib, ref.maghrib);
      expect(ours.maghrib.toUtc().hour * 60 + ours.maghrib.toUtc().minute,
          14 * 60 + 49, reason: '17:49 بتوقيت الرياض (UTC+3)');
      // أول رمضان 1447: العشاء = المغرب + 120.
      expect(ours.isha.difference(ours.maghrib).inMinutes, 120);
    });

    test('ارتفاع GPS المخزّن في الموقع لا يؤثّر في المواقيت', () {
      final date = DateTime(2026, 2, 18);
      final withAltitude = computeDayTimes(
          const LocationData(
              latitude: 24.7136, longitude: 46.6753, altitude: 612),
          date,
          method);
      expect(withAltitude.maghrib, adhanTimes(riyadh, date).maghrib);
      expect(withAltitude.sunrise, adhanTimes(riyadh, date).sunrise);
    });
  });

  group('الارتفاع فوق الأفق المحيط (خيار متقدّم)', () {
    final date = DateTime(2026, 3, 20);
    final low = computeDayTimes(mecca, date, method);
    final top = computeDayTimes(mecca, date, method, horizonHeight: 1500);

    test('مكة 277م ⇒ المغرب يتأخّر ~2.5 دقيقة (مقرَّبة للأعلى)', () {
      final t = computeDayTimes(mecca, date, method, horizonHeight: 277);
      final shift = t.maghrib.difference(low.maghrib).inMinutes;
      expect(shift, inInclusiveRange(2, 3));
      expect(t.maghrib.second, 0);
    });

    test('المغرب يتأخّر والشروق يتقدّم', () {
      expect(top.maghrib.isAfter(low.maghrib), isTrue);
      expect(top.sunrise.isBefore(low.sunrise), isTrue);
    });

    test('الفجر والظهر والعصر لا تتأثّر', () {
      expect(top.fajr, low.fajr);
      expect(top.dhuhr, low.dhuhr);
      expect(top.asr, low.asr);
    });

    test('العشاء الفاصلي في أم القرى يتبع المغرب', () {
      expect(top.isha.difference(top.maghrib), low.isha.difference(low.maghrib));
    });

    test('إزاحة المغرب ضمن المدى المتوقّع لـ1500م (~6 دقائق)', () {
      final shift = top.maghrib.difference(low.maghrib).inMinutes;
      expect(shift, inInclusiveRange(4, 9));
    });

    test('تقريب احتياطي: المغرب للأعلى والشروق للأسفل', () {
      final t = computeDayTimes(mecca, date, method, horizonHeight: 50);
      expect(t.maghrib.second, 0);
      expect(t.sunrise.second, 0);
      expect(t.maghrib.isAfter(low.maghrib), isTrue); // أي كسر يرفعه دقيقة
      expect(t.sunrise.isBefore(low.sunrise), isTrue);
    });
  });

  group('عشاء أم القرى الفاصلي (90/120 دقيقة)', () {
    test('خارج رمضان = المغرب + 90 دقيقة', () {
      final t = computeDayTimes(mecca, DateTime(2025, 6, 15), method);
      expect(t.isha.difference(t.maghrib).inMinutes, 90);
    });

    test('في رمضان = المغرب + 120 دقيقة', () {
      // 2025-03-15 يقع داخل رمضان 1446 (بدأ 2025-03-01).
      final t = computeDayTimes(mecca, DateTime(2025, 3, 15), method);
      expect(t.isha.difference(t.maghrib).inMinutes, 120);
    });
  });
}
