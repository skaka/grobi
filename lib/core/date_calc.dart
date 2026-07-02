/// حساب الفرق بين تاريخين كسنوات/أشهر/أيام — بالتقويمين الميلادي والهجري.
library;

import 'package:hijri/hijri_calendar.dart';

/// فرق مُفصَّل بين تاريخين: سنوات وأشهر وأيام (بعد استعارة الحدود).
class YmdDiff {
  final int years;
  final int months;
  final int days;
  const YmdDiff(this.years, this.months, this.days);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// عدد أيام شهر ميلادي (يراعي كبيسة فبراير).
int gregorianDaysInMonth(int year, int month) {
  const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month == 2) {
    final leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    return leap ? 29 : 28;
  }
  return lengths[month - 1];
}

/// الفرق (سنة/شهر/يوم) بين تاريخَي بدايةٍ ونهايةٍ مُمثَّلين بـ(سنة، شهر، يوم)،
/// مع دالة [daysInMonth] الخاصة بالتقويم لاستعارة أيام الشهر السابق. يفترض
/// أنّ تاريخ البداية ≤ تاريخ النهاية.
YmdDiff ymdDiff(
  int fy,
  int fm,
  int fd,
  int ty,
  int tm,
  int td,
  int Function(int year, int month) daysInMonth,
) {
  int years = ty - fy;
  int months = tm - fm;
  int days = td - fd;
  if (days < 0) {
    months -= 1;
    // نستعير أيام الشهر الذي يسبق شهر النهاية.
    var by = ty;
    var bm = tm - 1;
    if (bm < 1) {
      bm = 12;
      by -= 1;
    }
    days += daysInMonth(by, bm);
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }
  return YmdDiff(years, months, days);
}

/// حصيلة حساب المدة بين تاريخين ميلاديين: الفرق بالتقويمين + الإجماليات.
class DurationBreakdown {
  final YmdDiff gregorian;
  final YmdDiff hijri;
  final int totalDays;
  const DurationBreakdown({
    required this.gregorian,
    required this.hijri,
    required this.totalDays,
  });

  int get totalWeeks => totalDays ~/ 7;
}

/// يحسب المدة بين تاريخين ميلاديين. يرتّب التاريخين تلقائياً (الأقدم أولاً)،
/// فالنتيجة دائماً موجبة بصرف النظر عن ترتيب الإدخال.
DurationBreakdown durationBetween(DateTime a, DateTime b) {
  var from = _dateOnly(a);
  var to = _dateOnly(b);
  if (to.isBefore(from)) {
    final t = from;
    from = to;
    to = t;
  }

  final greg = ymdDiff(
    from.year,
    from.month,
    from.day,
    to.year,
    to.month,
    to.day,
    gregorianDaysInMonth,
  );

  final fromH = HijriCalendar.fromDate(from);
  final toH = HijriCalendar.fromDate(to);
  final hijri = ymdDiff(
    fromH.hYear,
    fromH.hMonth,
    fromH.hDay,
    toH.hYear,
    toH.hMonth,
    toH.hDay,
    (year, month) => HijriCalendar().getDaysInMonth(year, month),
  );

  return DurationBreakdown(
    gregorian: greg,
    hijri: hijri,
    totalDays: to.difference(from).inDays,
  );
}
