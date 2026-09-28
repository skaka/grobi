import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/ghuroubi_clock.dart';
import 'package:timer_grobi/core/ghuroubi_date.dart';
import 'package:timer_grobi/models/day_times.dart';

void main() {
  // أوقات غروب/شروق ثابتة لاختبار محدّد.
  final yMaghrib = DateTime(2025, 6, 14, 18, 0); // غروب الأمس
  final sunrise = DateTime(2025, 6, 15, 5, 0); // شروق اليوم
  final maghrib = DateTime(2025, 6, 15, 18, 0); // غروب اليوم
  final tMaghrib = DateTime(2025, 6, 16, 18, 0); // غروب الغد

  group('الساعة الغروبية', () {
    test('عند الغروب تماماً ⇒ 12:00', () {
      final c = GhuroubiClock.at(
        now: maghrib,
        yesterdayMaghrib: yMaghrib,
        todaySunrise: sunrise,
        todayMaghrib: maghrib,
        tomorrowMaghrib: tMaghrib,
      );
      expect(c.hour12, 12);
      expect(c.minute, 0);
      expect(c.format(), '12:00');
    });

    test('بعد الغروب بساعتين و30 دقيقة ⇒ 2:30', () {
      final c = GhuroubiClock.at(
        now: maghrib.add(const Duration(hours: 2, minutes: 30)),
        yesterdayMaghrib: yMaghrib,
        todaySunrise: sunrise,
        todayMaghrib: maghrib,
        tomorrowMaghrib: tMaghrib,
      );
      expect(c.hour12, 2);
      expect(c.minute, 30);
      expect(c.isDaytime, isFalse);
    });

    test('قبل غروب اليوم (نهاراً) يعتمد على غروب الأمس', () {
      // الساعة 12:00 ظهراً = بعد غروب الأمس بـ 18 ساعة ⇒ وجه: 12+18=30 ⇒ 6:00
      final c = GhuroubiClock.at(
        now: DateTime(2025, 6, 15, 12, 0),
        yesterdayMaghrib: yMaghrib,
        todaySunrise: sunrise,
        todayMaghrib: maghrib,
        tomorrowMaghrib: tMaghrib,
      );
      expect(c.hour12, 6);
      expect(c.minute, 0);
      expect(c.isDaytime, isTrue);
    });

    test('تجاوز منتصف الليل لا يكسر اعتماد آخر غروب', () {
      // 1:00 صباحاً = بعد غروب الأمس بـ 7 ساعات ⇒ 12+7=19 ⇒ 7:00
      final c = GhuroubiClock.at(
        now: DateTime(2025, 6, 15, 1, 0),
        yesterdayMaghrib: yMaghrib,
        todaySunrise: sunrise,
        todayMaghrib: maghrib,
        tomorrowMaghrib: tMaghrib,
      );
      expect(c.hour12, 7);
      expect(c.isDaytime, isFalse);
    });

    test('نسبة انقضاء اليوم الغروبي عند منتصف الليلة الغروبية ≈ 0.5', () {
      // منتصف بين غروب اليوم وغروب الغد = منتصف الليلة + ... نستخدم منتصف المدة
      final mid = maghrib.add(const Duration(hours: 12));
      final c = GhuroubiClock.at(
        now: mid,
        yesterdayMaghrib: yMaghrib,
        todaySunrise: sunrise,
        todayMaghrib: maghrib,
        tomorrowMaghrib: tMaghrib,
      );
      expect(c.dayProgress, closeTo(0.5, 0.01));
    });
  });

  group('التاريخ الغروبي', () {
    test('قبل الغروب ⇒ نفس التاريخ الميلادي', () {
      final d = ghuroubiCivilDate(DateTime(2025, 6, 15, 12), maghrib);
      expect(d, DateTime(2025, 6, 15));
    });

    test('بعد الغروب ⇒ التاريخ التالي', () {
      final d = ghuroubiCivilDate(DateTime(2025, 6, 15, 19), maghrib);
      expect(d, DateTime(2025, 6, 16));
    });

    test('التعديل اليدوي ±يوم يغيّر اليوم الهجري', () {
      final base = ghuroubiHijri(DateTime(2025, 6, 15), 0);
      final plus = ghuroubiHijri(DateTime(2025, 6, 15), 1);
      // فرق يوم ميلادي = فرق يوم هجري (ضمن نفس الشهر هنا)
      expect(plus.hDay - base.hDay, anyOf(1, -29, -28));
    });
  });

  group('اسم اليوم الغروبي', () {
    // الخميس 2026-10-01: فجر 04:40، مغرب 18:00.
    DayTimes thursday() => DayTimes(
          fajr: DateTime(2026, 10, 1, 4, 40),
          sunrise: DateTime(2026, 10, 1, 6),
          dhuhr: DateTime(2026, 10, 1, 12),
          asr: DateTime(2026, 10, 1, 15, 20),
          maghrib: DateTime(2026, 10, 1, 18),
          isha: DateTime(2026, 10, 1, 19, 30),
        );

    test('نهار الخميس ⇒ «الخميس»', () {
      expect(ghuroubiDayName(DateTime(2026, 10, 1, 12), thursday()), 'الخميس');
    });

    test('بعد مغرب الخميس ⇒ «ليلة الجمعة» (بجوار تاريخ الجمعة الغروبي)', () {
      expect(ghuroubiDayName(DateTime(2026, 10, 1, 18), thursday()),
          'ليلة الجمعة');
      expect(ghuroubiDayName(DateTime(2026, 10, 1, 23, 30), thursday()),
          'ليلة الجمعة');
    });

    test('قبل فجر الخميس ⇒ «ليلة الخميس»', () {
      expect(ghuroubiDayName(DateTime(2026, 10, 1, 2), thursday()),
          'ليلة الخميس');
    });
  });
}
