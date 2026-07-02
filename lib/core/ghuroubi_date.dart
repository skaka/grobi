import 'package:hijri/hijri_calendar.dart';

/// التاريخ الميلادي **الغروبي**: اليوم يبدأ عند الغروب، فبعد غروب [todaySunset]
/// نتقدّم يوماً واحداً (لأن اليوم الإسلامي الجديد قد بدأ).
DateTime ghuroubiCivilDate(DateTime now, DateTime todaySunset) {
  final base = DateTime(now.year, now.month, now.day);
  return now.isBefore(todaySunset) ? base : base.add(const Duration(days: 1));
}

/// التاريخ الهجري الغروبي من التاريخ الميلادي الغروبي، مع تعديل يدوي
/// [adjustDays] (±يوم) ليطابق رؤية أم القرى المحلية.
HijriCalendar ghuroubiHijri(DateTime ghuroubiCivil, int adjustDays) {
  return HijriCalendar.fromDate(
    ghuroubiCivil.add(Duration(days: adjustDays)),
  );
}
