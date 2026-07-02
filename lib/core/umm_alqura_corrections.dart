import 'package:hijri/hijri_calendar.dart';

import '../models/islamic_event.dart';

/// تصحيح تقويم أم القرى (المضمَّن في حزمة `hijri`) من إعلانات الرؤية المؤكّدة.
///
/// الحزمة تحمل جدول أم القرى الرسمي، وتوفّر آلية «تعديلات» (`adjustments`) تُلغي
/// إدخالاً محدّداً من الجدول: المفتاح = ترتيب بداية الشهر الهجري المطلق، والقيمة =
/// «mcjdn» (Modified Chronological Julian Day Number) ليوم بداية الشهر. تحريك هذا
/// الحدّ يُصحّح الاتجاهين (ميلادي↔هجري) وأطوال الأشهر معاً، ويُمتَصّ فرق ±اليوم في
/// الشهر السابق تلقائياً.

/// مدى جدول أم القرى في الحزمة: 1356..1500 هـ — نتجنّب الحواف احتياطاً.
const int _minHYear = 1357;
const int _maxHYear = 1499;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// «mcjdn» ليوم ميلادي — بنفس صيغة `HijriCalendar.gregorianToHijri` (CJDN − 2400000).
int gregorianToMcjdn(DateTime g) {
  int y = g.year;
  int m = g.month;
  final int day = g.day;
  // ألحِق يناير/فبراير بالسنة السابقة (مارس = أول الشهور) لتبسيط الكبائس.
  if (m < 3) {
    y -= 1;
    m += 12;
  }
  final int a = (y / 100).floor();
  final int jgc = a - (a / 4.0).floor() - 2;
  final int cjdn = (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day -
      jgc -
      1524;
  return cjdn - 2400000;
}

/// مفتاح `adjustments` لبداية الشهر (hYear, hMonth) — يطابق فهرسة الحزمة.
int adjustmentKey(int hYear, int hMonth) => (hYear - 1) * 12 + hMonth - 1;

/// يبني خريطة تصحيحات جدول أم القرى من إعلانات الرؤية.
/// كل إعلان يثبّت بداية شهره في تاريخه الميلادي المؤكّد. عند تكرار نفس الشهر
/// يفوز الأحدث (آخر إعلان في القائمة).
Map<int, int> adjustmentsFromAnnouncements(
    List<EventAnnouncement> announcements) {
  final map = <int, int>{};
  for (final a in announcements) {
    if (a.hijriYear < _minHYear || a.hijriYear > _maxHYear) continue;
    map[adjustmentKey(a.hijriYear, a.type.hijriMonth)] =
        gregorianToMcjdn(_dateOnly(a.gregorianDate));
  }
  return map;
}

/// تاريخ هجري مُصحَّح من تاريخ ميلادي، مع إزاحة يدوية عامة احتياطية [manualAdjust].
HijriCalendar correctedHijri(DateTime gregorian, Map<int, int> adjustments,
    {int manualAdjust = 0}) {
  final h = HijriCalendar()..adjustments = adjustments;
  final d = gregorian.add(Duration(days: manualAdjust));
  h.gregorianToHijri(d.year, d.month, d.day);
  return h;
}

/// أول يوم ميلادي لشهر هجري (بعد التصحيح).
DateTime correctedMonthStart(int hYear, int hMonth, Map<int, int> adjustments) {
  final h = HijriCalendar()..adjustments = adjustments;
  return _dateOnly(h.hijriToGregorian(hYear, hMonth, 1));
}

/// عدد أيام شهر هجري (بعد التصحيح): 29 أو 30.
int correctedMonthLength(int hYear, int hMonth, Map<int, int> adjustments) {
  final h = HijriCalendar()..adjustments = adjustments;
  return h.getDaysInMonth(hYear, hMonth);
}
