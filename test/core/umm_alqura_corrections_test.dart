import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timer_grobi/core/umm_alqura_corrections.dart';
import 'package:timer_grobi/models/islamic_event.dart';

void main() {
  DateTime d0(DateTime d) => DateTime(d.year, d.month, d.day);

  // مراجع من جدول أم القرى غير المُصحَّح (1447 هـ).
  final pkgRamadan = d0(HijriCalendar().hijriToGregorian(1447, 9, 1));
  final pkgShawwal = d0(HijriCalendar().hijriToGregorian(1447, 10, 1));
  final defaultRamadanLen = HijriCalendar().getDaysInMonth(1447, 9);
  final defaultShaabanLen = HijriCalendar().getDaysInMonth(1447, 8);

  EventAnnouncement ann(IslamicEventType type, int year, DateTime g) =>
      EventAnnouncement(type: type, hijriYear: year, gregorianDate: g);

  group('adjustmentsFromAnnouncements + round-trip', () {
    test('تثبيت بداية رمضان يطابق التاريخ المُعلَن بالضبط', () {
      final announced = pkgRamadan.add(const Duration(days: 1));
      final adj = adjustmentsFromAnnouncements(
          [ann(IslamicEventType.ramadan, 1447, announced)]);
      expect(correctedMonthStart(1447, 9, adj), announced);
    });

    test('تثبيت مطابق للجدول لا يغيّر البداية', () {
      final adj = adjustmentsFromAnnouncements(
          [ann(IslamicEventType.ramadan, 1447, pkgRamadan)]);
      expect(correctedMonthStart(1447, 9, adj), pkgRamadan);
    });

    test('يتجاهل السنوات خارج مدى الجدول', () {
      expect(adjustmentsFromAnnouncements([ann(IslamicEventType.ramadan, 0, pkgRamadan)]),
          isEmpty);
    });
  });

  group('طول الشهر من التثبيتات', () {
    test('رمضان+العيد ⇒ طول رمضان = الفرق (30)', () {
      final r = pkgRamadan;
      final adj = adjustmentsFromAnnouncements([
        ann(IslamicEventType.ramadan, 1447, r),
        ann(IslamicEventType.eidFitr, 1447, r.add(const Duration(days: 30))),
      ]);
      expect(correctedMonthLength(1447, 9, adj), 30);
    });

    test('رمضان+العيد ⇒ طول رمضان = الفرق (29)', () {
      final r = pkgRamadan;
      final adj = adjustmentsFromAnnouncements([
        ann(IslamicEventType.ramadan, 1447, r),
        ann(IslamicEventType.eidFitr, 1447, r.add(const Duration(days: 29))),
      ]);
      expect(correctedMonthLength(1447, 9, adj), 29);
    });

    test('تثبيت رمضان +يوم ⇒ شعبان يمتصّ الفرق', () {
      final adj = adjustmentsFromAnnouncements(
          [ann(IslamicEventType.ramadan, 1447, pkgRamadan.add(const Duration(days: 1)))]);
      expect(correctedMonthStart(1447, 9, adj),
          pkgRamadan.add(const Duration(days: 1)));
      expect(correctedMonthLength(1447, 8, adj), defaultShaabanLen + 1);
    });
  });

  group('ميلادي↔هجري', () {
    test('بلا تصحيح = جدول أم القرى الأصلي', () {
      final g = DateTime(2025, 6, 15);
      final c = correctedHijri(g, const {});
      final base = HijriCalendar.fromDate(g);
      expect([c.hYear, c.hMonth, c.hDay],
          [base.hYear, base.hMonth, base.hDay]);
    });

    test('حول تثبيت رمضان: اليوم المُعلَن = رمضان ١، وما قبله = آخر شعبان', () {
      final announced = pkgRamadan.add(const Duration(days: 1));
      final adj = adjustmentsFromAnnouncements(
          [ann(IslamicEventType.ramadan, 1447, announced)]);
      final first = correctedHijri(announced, adj);
      expect([first.hMonth, first.hDay], [9, 1]);
      final prev = correctedHijri(announced.subtract(const Duration(days: 1)), adj);
      expect(prev.hMonth, 8);
    });

    test('الإزاحة اليدوية العامة تُطبَّق', () {
      final g = DateTime(2025, 6, 15);
      final a = correctedHijri(g, const {}, manualAdjust: 1);
      final b = correctedHijri(g.add(const Duration(days: 1)), const {});
      expect([a.hYear, a.hMonth, a.hDay], [b.hYear, b.hMonth, b.hDay]);
    });
  });

  // يُبقي على استعمال المرجع كي لا يُحذَف بالتحليل الساكن.
  test('مراجع الجدول الافتراضية معقولة', () {
    expect(defaultRamadanLen, anyOf(29, 30));
    expect(pkgShawwal.isAfter(pkgRamadan), isTrue);
  });
}
