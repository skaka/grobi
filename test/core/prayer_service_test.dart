import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/prayer_service.dart';
import 'package:timer_grobi/models/location_data.dart';

void main() {
  final date = DateTime(2025, 6, 15);
  const sea = LocationData(latitude: 21.42, longitude: 39.83, altitude: 0);
  const high = LocationData(latitude: 21.42, longitude: 39.83, altitude: 1500);

  group('تأثير الارتفاع على المواقيت (أم القرى)', () {
    final low = computeDayTimes(sea, date, CalculationMethod.umm_al_qura);
    final top = computeDayTimes(high, date, CalculationMethod.umm_al_qura);

    test('المغرب يتأخّر بالارتفاع', () {
      expect(top.maghrib.isAfter(low.maghrib), isTrue);
    });

    test('الشروق يتقدّم بالارتفاع', () {
      expect(top.sunrise.isBefore(low.sunrise), isTrue);
    });

    test('الفجر لا يتأثّر بالارتفاع (زاوية شفق)', () {
      expect(top.fajr, low.fajr);
    });

    test('العصر لا يتأثّر بالارتفاع (نسبة ظلّ)', () {
      expect(top.asr, low.asr);
    });

    test('العشاء يتأخّر بالارتفاع (فاصلي عن المغرب في أم القرى)', () {
      expect(top.isha.isAfter(low.isha), isTrue);
    });

    test('الظهر لا يتأثّر بالارتفاع (لحظة الزوال)', () {
      expect(top.dhuhr, low.dhuhr);
    });

    test('إزاحة المغرب ضمن المدى المتوقّع لـ1500م (~6 دقائق)', () {
      final shift = top.maghrib.difference(low.maghrib).inSeconds / 60.0;
      expect(shift, inInclusiveRange(4.0, 9.0));
    });
  });

  group('عشاء أم القرى الفاصلي (90/120 دقيقة)', () {
    test('خارج رمضان = المغرب + 90 دقيقة', () {
      final t = computeDayTimes(sea, DateTime(2025, 6, 15),
          CalculationMethod.umm_al_qura);
      expect(t.isha.difference(t.maghrib).inMinutes, inInclusiveRange(88, 92));
    });

    test('في رمضان = المغرب + 120 دقيقة', () {
      // 2025-03-15 يقع داخل رمضان 1446 (بدأ ~2025-03-01).
      final t = computeDayTimes(sea, DateTime(2025, 3, 15),
          CalculationMethod.umm_al_qura);
      expect(t.isha.difference(t.maghrib).inMinutes, inInclusiveRange(118, 122));
    });
  });
}
