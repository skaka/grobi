import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/astronomy.dart';
import 'package:timer_grobi/core/solar_time.dart';
import 'package:timer_grobi/core/elevation.dart';

void main() {
  group('astronomy — معادلة الزمن', () {
    test('قيمة قصوى موجبة قرب 3 نوفمبر (~+16 دقيقة)', () {
      final eot = equationOfTime(DateTime.utc(2025, 11, 3, 12));
      expect(eot, inInclusiveRange(15.0, 18.0));
    });

    test('قيمة دنيا سالبة قرب 11 فبراير (~−14 دقيقة)', () {
      final eot = equationOfTime(DateTime.utc(2025, 2, 11, 12));
      expect(eot, inInclusiveRange(-16.0, -12.0));
    });
  });

  group('astronomy — ميل الشمس', () {
    test('الانقلاب الصيفي ≈ +23.44°', () {
      expect(solarDeclination(DateTime.utc(2025, 6, 21, 12)),
          inInclusiveRange(23.0, 23.7));
    });

    test('الانقلاب الشتوي ≈ −23.44°', () {
      expect(solarDeclination(DateTime.utc(2025, 12, 21, 12)),
          inInclusiveRange(-23.7, -23.0));
    });

    test('الاعتدال الربيعي ≈ 0°', () {
      expect(solarDeclination(DateTime.utc(2025, 3, 20, 12)).abs(),
          lessThan(1.0));
    });
  });

  group('astronomy — الزاوية الساعية', () {
    test('خط الاستواء، اعتدال، أفق 0.833° ⇒ ~90.83°', () {
      expect(hourAngle(0.833, 0, 0), closeTo(90.83, 0.2));
    });

    test('منطقة قطبية صيفاً (شمس لا تغيب) ⇒ NaN', () {
      expect(hourAngle(0.833, 80, 23.4).isNaN, isTrue);
    });
  });

  group('solar_time — التوقيت الشمسي الحقيقي', () {
    test('خط طول 0 وEoT≈0 ⇒ الشمسي ≈ UTC', () {
      // 1 سبتمبر EoT قريب من الصفر
      final s = solarTime(DateTime.utc(2025, 9, 1, 12, 0, 0), 0);
      expect(s.totalMinutes, closeTo(12 * 60, 3.0));
    });

    test('فرق مكة عن خط الطول 0 = 39.8/15 ساعة ثابت', () {
      final instant = DateTime.utc(2025, 9, 1, 9, 0, 0);
      final mecca = solarTime(instant, 39.8).totalMinutes;
      final zero = solarTime(instant, 0).totalMinutes;
      expect(mecca - zero, closeTo(39.8 / 15 * 60, 1.0));
    });
  });

  group('elevation — تصحيح الارتفاع', () {
    final date = DateTime.utc(2025, 6, 15, 12);

    test('ارتفاع صفر ⇒ 0', () {
      expect(elevationDeltaMinutes(21.4, date, 0), 0.0);
    });

    test('ارتفاع سالب ⇒ 0', () {
      expect(elevationDeltaMinutes(21.4, date, -5), 0.0);
    });

    test('مكة (277م) ⇒ ~2.7 دقيقة', () {
      expect(elevationDeltaMinutes(21.4, date, 277),
          inInclusiveRange(2.0, 3.5));
    });

    test('1000م ⇒ ~5 دقائق', () {
      expect(elevationDeltaMinutes(21.4, date, 1000),
          inInclusiveRange(4.0, 6.5));
    });

    test('منطقة قطبية (NaN) ⇒ 0', () {
      expect(elevationDeltaMinutes(80, DateTime.utc(2025, 6, 21, 12), 1000),
          0.0);
    });
  });
}
