import 'dart:io' show Platform;

import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/date_calc.dart';
import 'package:timer_grobi/core/date_utils.dart';
import 'package:timer_grobi/core/ghuroubi_date.dart';
import 'package:timer_grobi/core/prayer_service.dart';
import 'package:timer_grobi/core/umm_alqura_corrections.dart';
import 'package:timer_grobi/models/day_times.dart';
import 'package:timer_grobi/models/islamic_event.dart';
import 'package:timer_grobi/models/location_data.dart';
import 'package:timer_grobi/providers/time_providers.dart';

/// الأيام التقويمية عبر انتقالات التوقيت الصيفي.
///
/// Dart يقرأ المنطقة الزمنية من متغيّر البيئة `TZ` عند بدء العملية ولا يمكن تغييرها
/// داخلها، لذا تنجح هذه الاختبارات تحت أي منطقة، ويشغّلها `tool/test_dst.sh` تحت
/// الدار البيضاء والقاهرة وبيروت ولندن حيث تنكسر إضافة 24 ساعة فعلاً.

/// انتقالات الساعة المعروفة في المدى المختبَر (يوم ليس 24 ساعة) لكل منطقة.
const _transitionDays = <String, List<(int, int, int)>>{
  // المغرب يؤخّر ساعته حول رمضان ثم يعيدها.
  'Africa/Casablanca': [(2026, 2, 15), (2026, 3, 22), (2027, 2, 7), (2027, 3, 14)],
  'Africa/Cairo': [(2026, 4, 24), (2026, 10, 29)],
  'Asia/Beirut': [(2026, 3, 29), (2026, 10, 24)], // التأخير عند منتصف الليل: يوم 24 طوله 25 ساعة
  'Europe/London': [(2026, 3, 29), (2026, 10, 25)],
};

const _cities = <String, LocationData>{
  'الدار البيضاء': LocationData(latitude: 33.5731, longitude: -7.5898),
  'القاهرة': LocationData(latitude: 30.0444, longitude: 31.2357),
  'بيروت': LocationData(latitude: 33.8938, longitude: 35.5018),
  'لندن': LocationData(latitude: 51.5074, longitude: -0.1278),
};

void main() {
  final tz = Platform.environment['TZ'];

  test('المنطقة الزمنية المطلوبة فعّالة (TZ=${tz ?? 'الجهاز'})', () {
    final days = _transitionDays[tz];
    if (days == null) return; // منطقة الجهاز الافتراضية — لا انتقالات معروفة
    for (final (y, m, d) in days) {
      final length = DateTime(y, m, d + 1).difference(DateTime(y, m, d));
      expect(length, isNot(const Duration(hours: 24)),
          reason: '$y-$m-$d يجب أن يكون يوم انتقال في $tz');
    }
  });

  group('أدوات الأيام', () {
    test('addDays يحافظ على الحقول عبر كل الانتقالات', () {
      for (final days in _transitionDays.values) {
        for (final (y, m, d) in days) {
          final day = DateTime(y, m, d);
          expect(addDays(day, 1), DateTime(y, m, d + 1));
          expect(addDays(addDays(day, 1), -1).day, d);
          expect(addDays(day, 1).day, DateTime(y, m, d + 1).day);
          expect(daysBetween(day, addDays(day, 1)), 1);
          expect(daysBetween(addDays(day, 1), day), -1);
        }
      }
    });

    test('daysBetween وحاسبة المدة لا تنقصان يوماً عبر تقديم الساعة', () {
      expect(daysBetween(DateTime(2026, 3, 1), DateTime(2026, 4, 1)), 31);
      expect(daysBetween(DateTime(2026, 1, 1), DateTime(2026, 7, 1)), 181);
      expect(
          durationBetween(DateTime(2026, 1, 1), DateTime(2026, 7, 1)).totalDays,
          181);
    });
  });

  group('شبكة التقويم الهجري', () {
    // 1447/1 .. 1449/12 = يونيو 2025 .. مايو 2028: تشمل كل الانتقالات أعلاه.
    final anchored = buildAnchoring([
      EventAnnouncement(
          type: IslamicEventType.ramadan,
          hijriYear: 1447,
          gregorianDate: DateTime(2026, 2, 19)), // +1 عن الجدول
      EventAnnouncement(
          hijriYear: 1448, hijriMonth: 5, gregorianDate: DateTime(2026, 10, 11)),
    ]).adjustments;

    for (final (label, adjustments, manual) in [
      ('الجدول', const <int, int>{}, 0),
      ('مع تثبيتات', anchored, 0),
      ('مع إزاحة يدوية +1', const <int, int>{}, 1),
      ('مع إزاحة يدوية −1 وتثبيتات', anchored, -1),
    ]) {
      test('كل خلية يوم تقويمي تالٍ ويطابق يومها الهجري — $label', () {
        DateTime? previousEnd;
        for (var ordinal = 1447 * 12; ordinal < 1450 * 12; ordinal++) {
          final hYear = ordinal ~/ 12;
          final hMonth = ordinal % 12 + 1;
          final grid = hijriMonthGrid(hYear, hMonth, adjustments,
              manualAdjust: manual);

          expect(grid.days.length, anyOf(29, 30), reason: '$hMonth/$hYear');
          if (previousEnd != null) {
            expect(daysBetween(previousEnd, grid.start), 1,
                reason: 'استمرارية $hMonth/$hYear');
          }
          for (var i = 0; i < grid.days.length; i++) {
            final day = grid.days[i];
            if (i > 0) {
              expect(daysBetween(grid.days[i - 1], day), 1,
                  reason: 'خلية ${i + 1} من $hMonth/$hYear = $day');
            }
            final h = correctedHijri(day, adjustments, manualAdjust: manual);
            expect([h.hYear, h.hMonth, h.hDay], [hYear, hMonth, i + 1],
                reason: '$day');
          }
          previousEnd = grid.end;
        }
      });
    }
  });

  group('اليوم الغروبي', () {
    final method = CalculationMethod.umm_al_qura;

    for (final MapEntry(key: name, value: loc) in _cities.entries) {
      test('التاريخ يتقدّم مرة واحدة بالضبط عند كل غروب — $name', () {
        final cache = <DateTime, DayTimes>{};
        DayTimes timesFor(DateTime date) {
          expect(date, dateOnly(date), reason: 'مفتاح يوم بلا وقت');
          return cache.putIfAbsent(
              date, () => computeDayTimes(loc, date, method));
        }

        // لحظات حقيقية كل ساعة (لا ساعات جدارية) من يناير 2026 إلى أبريل 2027.
        final end = DateTime.utc(2027, 4, 30).millisecondsSinceEpoch;
        var ms = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
        DateTime? prevNow;
        GhuroubiDay? prev;
        for (; ms < end; ms += 3600 * 1000) {
          final now = DateTime.fromMillisecondsSinceEpoch(ms);
          final day = ghuroubiDayAt(now, timesFor);

          expect(daysBetween(now, day.civilDate), anyOf(0, 1), reason: '$now');
          expect(day.nextSunset.isAfter(now), isTrue,
              reason: 'الغروب القادم بعد اللحظة: $now');
          expect(day.nextSunset.difference(now),
              lessThanOrEqualTo(const Duration(hours: 26)),
              reason: '$now');
          expect(day.clock.sinceSunset.isNegative, isFalse, reason: '$now');
          expect(day.clock.sinceSunset,
              lessThanOrEqualTo(const Duration(hours: 26)),
              reason: 'آخر غروب هو غروب الأمس لا ما قبله: $now');

          if (prev != null && prevNow != null) {
            final crossed = prevNow.isBefore(prev.nextSunset) &&
                !now.isBefore(prev.nextSunset);
            expect(daysBetween(prev.civilDate, day.civilDate), crossed ? 1 : 0,
                reason: 'بين $prevNow و$now');
          }
          prevNow = now;
          prev = day;
        }
      });
    }

    test('ليلة الترائي 30 شعبان 1448 (يوم انتقال المغرب): عشاء رمضان +120', () {
      final casablanca = _cities['الدار البيضاء']!;
      expect(correctedHijri(DateTime(2027, 2, 8), const {}).hMonth, 9);
      final sightingNight =
          computeDayTimes(casablanca, DateTime(2027, 2, 7), method);
      expect(sightingNight.isha.difference(sightingNight.maghrib).inMinutes,
          120);
      final dayBefore =
          computeDayTimes(casablanca, DateTime(2027, 2, 6), method);
      expect(dayBefore.isha.difference(dayBefore.maghrib).inMinutes, 90);
    });
  });

  test('مؤقّت الدقيقة ينتظر حتى حدّها التالي حتى في الساعة المكرّرة', () {
    for (final utc in [
      DateTime.utc(2026, 2, 15, 1, 30, 20), // الدار البيضاء: الساعة 02 تتكرّر
      DateTime.utc(2026, 2, 15, 2, 30, 20),
      DateTime.utc(2026, 10, 25, 0, 30, 20), // لندن: الساعة 01 تتكرّر
      DateTime.utc(2026, 10, 25, 1, 30, 20),
      DateTime.utc(2026, 10, 28, 21, 59, 59, 999), // القاهرة
    ]) {
      final now = utc.toLocal();
      final wait = millisUntilNextMinute(now);
      expect(wait, inInclusiveRange(1, 60000), reason: '$now');
      expect((now.millisecondsSinceEpoch + wait) % 60000, 0);
    }
  });
}
