import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timer_grobi/core/date_utils.dart';
import 'package:timer_grobi/core/umm_alqura_corrections.dart';
import 'package:timer_grobi/models/islamic_event.dart';

/// أول يوم ميلادي للشهر في جدول أم القرى غير المُصحَّح.
DateTime tableStart(int y, int m) =>
    dateOnly(HijriCalendar().hijriToGregorian(y, m, 1));

EventAnnouncement anchor(int y, int m, DateTime g) =>
    EventAnnouncement(hijriYear: y, hijriMonth: m, gregorianDate: g);

EventAnnouncement named(IslamicEventType type, int y, DateTime g) =>
    EventAnnouncement(type: type, hijriYear: y, gregorianDate: g);

/// أطوال كل الأشهر (مفتاح → طول) بين مفتاحين بعد التصحيح.
Map<int, int> lengthsBetween(Map<int, int> adj, int fromKey, int toKey) {
  final h = HijriCalendar()..adjustments = adj;
  return {
    for (var k = fromKey; k <= toKey; k++)
      k: h.getDaysInMonth(k ~/ 12 + 1, k % 12 + 1),
  };
}

/// أشهر بطول غير صالح **أحدثها التصحيح** — جدول الحزمة نفسه فيه شذوذ تاريخي
/// واحد (شعبان 1364 = 28 يوماً) لا يُحسب على الخوارزمية ما دام لم يُمَسّ.
Map<int, int> invalidCreated(Map<int, int> adj, int fromKey, int toKey) {
  final lengths = lengthsBetween(adj, fromKey, toKey);
  final table = lengthsBetween(const {}, fromKey, toKey);
  return {
    for (final MapEntry(key: k, value: len) in lengths.entries)
      if (len != 29 && len != 30 && len != table[k]) k: len,
  };
}

void main() {
  group('التثبيت الأساسي', () {
    test('بداية رمضان المُعلَنة تُطابَق بالضبط، واليوم قبلها آخر شعبان', () {
      final announced = addDays(tableStart(1447, 9), 1);
      final adj = adjustmentsFromAnnouncements(
          [named(IslamicEventType.ramadan, 1447, announced)]);
      expect(correctedMonthStart(1447, 9, adj), announced);
      final first = correctedHijri(announced, adj);
      expect([first.hMonth, first.hDay], [9, 1]);
      expect(correctedHijri(addDays(announced, -1), adj).hMonth, 8);
    });

    test('تثبيت مطابق للجدول لا يغيّر شيئاً', () {
      final adj = adjustmentsFromAnnouncements(
          [named(IslamicEventType.ramadan, 1447, tableStart(1447, 9))]);
      expect(correctedMonthStart(1447, 9, adj), tableStart(1447, 9));
      for (final m in [7, 8, 9, 10]) {
        expect(correctedMonthLength(1447, m, adj),
            HijriCalendar().getDaysInMonth(1447, m));
      }
    });

    test('يتجاهل السنوات خارج مدى الجدول', () {
      expect(
          adjustmentsFromAnnouncements(
              [named(IslamicEventType.ramadan, 0, tableStart(1447, 9))]),
          isEmpty);
    });

    test('رمضان + العيد المُعلَنان يحدّدان طول رمضان (29 أو 30)', () {
      final r = tableStart(1447, 9);
      for (final length in [29, 30]) {
        final adj = adjustmentsFromAnnouncements([
          named(IslamicEventType.ramadan, 1447, r),
          named(IslamicEventType.eidFitr, 1447, addDays(r, length)),
        ]);
        expect(correctedMonthLength(1447, 9, adj), length);
      }
    });

    test('بلا تصحيح = جدول أم القرى الأصلي، والإزاحة اليدوية تُطبَّق', () {
      final g = DateTime(2025, 6, 15);
      final c = correctedHijri(g, const {});
      final base = HijriCalendar.fromDate(g);
      expect([c.hYear, c.hMonth, c.hDay], [base.hYear, base.hMonth, base.hDay]);
      final a = correctedHijri(g, const {}, manualAdjust: 1);
      final b = correctedHijri(addDays(g, 1), const {});
      expect([a.hYear, a.hMonth, a.hDay], [b.hYear, b.hMonth, b.hDay]);
    });
  });

  // السيناريوهات الثلاثة المقيسة: تحريك حدّ واحد (المنطق القديم) كان يولّد أشهراً
  // من 28 و31 يوماً. نثبت أولاً أن السيناريو يعيد إنتاج الخلل بالمنطق القديم، ثم
  // أن الخوارزمية الجديدة تُبقي كل شهر 29/30 مع احترام التاريخ المُعلَن.
  group('انحدار: السيناريوهات المقيسة', () {
    for (final (year, offset, oldShaban, oldRamadan) in [
      (1446, 1, 30, 28),
      (1447, -1, 28, 31),
      (1448, 1, 31, 28),
    ]) {
      test('$year رمضان ${offset > 0 ? '+' : ''}$offset يوم', () {
        final announced = addDays(tableStart(year, 9), offset);

        final old = {adjustmentKey(year, 9): gregorianToMcjdn(announced)};
        expect(correctedMonthLength(year, 8, old), oldShaban);
        expect(correctedMonthLength(year, 9, old), oldRamadan);

        final result = buildAnchoring(
            [named(IslamicEventType.ramadan, year, announced)]);
        expect(result.issues, isEmpty);
        final adj = result.adjustments;
        expect(correctedMonthStart(year, 9, adj), announced);
        final lengths = lengthsBetween(adj, adjustmentKey(year - 1, 1),
            adjustmentKey(year + 1, 12));
        expect(lengths.values.toSet().difference({29, 30}), isEmpty,
            reason: '$lengths');
      });
    }

    test('رمضان 28 كان يُظهر 1 شوّال مبكّراً — الآن يتأخّر شوّال المتوقَّع معه', () {
      final announced = addDays(tableStart(1448, 9), 1);
      final adj = adjustmentsFromAnnouncements(
          [named(IslamicEventType.ramadan, 1448, announced)]);
      final day29 = addDays(announced, 28);
      expect(correctedHijri(day29, adj).hMonth, 9);
      expect(correctedHijri(addDays(announced, 29), adj).hMonth, 10,
          reason: 'رمضان 29 يوماً (أقصر ما يمكن)، لا 28');
      expect(correctedMonthStart(1448, 10, adj),
          addDays(tableStart(1448, 10), 1));
    });

    test('إعلان شعبان وحده يزيح بداية رمضان المتوقَّعة قبل إعلانها', () {
      // شعبان 1447 في الجدول 29 يوماً: تأخّره يوماً يدفع رمضان يوماً.
      expect(HijriCalendar().getDaysInMonth(1447, 8), 29);
      final adj = adjustmentsFromAnnouncements([
        named(IslamicEventType.shaban, 1447, addDays(tableStart(1447, 8), 1)),
      ]);
      expect(correctedMonthStart(1447, 9, adj), addDays(tableStart(1447, 9), 1));
      expect(correctedMonthLength(1447, 8, adj), 29);
    });

    test('سجلّ الإنتاج الشارد (sa، محرّم 1448 = 2026-06-27، +11 يوماً) يُرفَض', () {
      final result = buildAnchoring([
        named(IslamicEventType.hijriNewYear, 1448, DateTime(2026, 6, 27)),
      ]);
      expect(result.adjustments, isEmpty);
      expect(result.issues.single, contains('رُفض'));
      // وكان يمدّ ذا الحجة 1447 إلى 40 يوماً بالمنطق القديم.
      final old = {
        adjustmentKey(1448, 1): gregorianToMcjdn(DateTime(2026, 6, 27)),
      };
      expect(correctedMonthLength(1447, 12, old), greaterThan(30));
    });

    test('فرق ±2 يُقبل، و±3 يُرفض', () {
      for (final k in [-2, 2]) {
        expect(
            buildAnchoring([anchor(1448, 3, addDays(tableStart(1448, 3), k))])
                .adjustments,
            isNotEmpty);
      }
      for (final k in [-3, 3]) {
        expect(
            buildAnchoring([anchor(1448, 3, addDays(tableStart(1448, 3), k))])
                .adjustments,
            isEmpty);
      }
    });

    test('التثبيت الصامت (بلا نوع) يصحّح شهره كالمسمّى', () {
      final announced = addDays(tableStart(1448, 5), -1);
      final adj = adjustmentsFromAnnouncements([anchor(1448, 5, announced)]);
      expect(correctedMonthStart(1448, 5, adj), announced);
    });

    test('تثبيتان متعارضان يُسجَّلان ولا يُحرَّك أيّ منهما', () {
      // رمضان +2 وشوّال −2: لا يتّسع رمضان لهما (25–26 يوماً).
      final ram = addDays(tableStart(1447, 9), 2);
      final shw = addDays(tableStart(1447, 10), -2);
      final result = buildAnchoring([
        named(IslamicEventType.ramadan, 1447, ram),
        named(IslamicEventType.eidFitr, 1447, shw),
      ]);
      expect(result.issues, isNotEmpty);
      expect(correctedMonthStart(1447, 9, result.adjustments), ram);
      expect(correctedMonthStart(1447, 10, result.adjustments), shw);
    });
  });

  group('خاصّية: كل شهر 29 أو 30 عبر 1357–1499', () {
    final minKey = adjustmentKey(1357, 1);
    final maxKey = adjustmentKey(1499, 12);

    test('جدول الحزمة: شذوذ تاريخي وحيد (شعبان 1364 = 28)', () {
      final table = lengthsBetween(const {}, minKey, maxKey);
      expect({
        for (final MapEntry(key: k, value: len) in table.entries)
          if (len != 29 && len != 30) k: len,
      }, {adjustmentKey(1364, 8): 28});
    });

    test('تثبيت واحد عشوائي ±1/±2 على شهر عشوائي', () {
      final rnd = Random(20260927);
      for (var i = 0; i < 400; i++) {
        final key = minKey + rnd.nextInt(maxKey - minKey + 1);
        final y = key ~/ 12 + 1, m = key % 12 + 1;
        final k = [-2, -1, 1, 2][rnd.nextInt(4)];
        final announced = addDays(tableStart(y, m), k);

        final result = buildAnchoring([anchor(y, m, announced)]);
        final adj = result.adjustments;
        expect(result.issues, isEmpty, reason: '$m/$y $k');
        expect(correctedMonthStart(y, m, adj), announced, reason: '$m/$y $k');

        // كل الأشهر حول التثبيت (والتغيير محصور قربه) 29/30.
        expect(
            invalidCreated(adj, max(minKey, key - 24), min(maxKey, key + 24)),
            isEmpty,
            reason: '$m/$y $k');
        for (final changed in adj.keys) {
          expect((changed - key).abs(), lessThanOrEqualTo(24),
              reason: 'تغيير بعيد عن التثبيت: $changed');
        }
      }
    });

    test('تثبيتات متعدّدة متّسقة من تقويم دولة عشوائي تُحترم كلها', () {
      final rnd = Random(1447);
      for (var run = 0; run < 150; run++) {
        // تقويم دولة صالح قرب الجدول: إزاحة ≤2 يوم وكل شهر 29/30.
        final first = minKey + rnd.nextInt(maxKey - minKey - 40);
        final span = 12 + rnd.nextInt(24);
        final country = <int, int>{};
        var offset = rnd.nextInt(3) - 1;
        for (var key = first; key <= first + span; key++) {
          country[key] = tableMonthStart(key) + offset;
          final tableLength = tableMonthStart(key + 1) - tableMonthStart(key);
          final choices = [
            for (final next in [offset - 1, offset, offset + 1])
              if (next.abs() <= 2 &&
                  {29, 30}.contains(tableLength + next - offset))
                next,
          ];
          offset = choices[rnd.nextInt(choices.length)];
        }

        final picked = (country.keys.toList()..shuffle(rnd))
            .take(1 + rnd.nextInt(8))
            .toList();
        final announcements = [
          for (final key in picked)
            anchor(key ~/ 12 + 1, key % 12 + 1,
                _mcjdnToDate(country[key]!)),
        ];

        final result = buildAnchoring(announcements);
        expect(result.issues, isEmpty, reason: 'run $run');
        for (final key in picked) {
          expect(correctedMonthStart(key ~/ 12 + 1, key % 12 + 1,
                  result.adjustments),
              _mcjdnToDate(country[key]!),
              reason: 'run $run key $key');
        }
        expect(
            invalidCreated(result.adjustments, max(minKey, first - 24),
                min(maxKey, first + span + 24)),
            isEmpty,
            reason: 'run $run');
      }
    });
  });
}

/// mcjdn → تاريخ ميلادي (عكس [gregorianToMcjdn]) عبر الحزمة نفسها.
DateTime _mcjdnToDate(int mcjdn) =>
    dateOnly(HijriCalendar().julianToGregorian(mcjdn + 2400000));
