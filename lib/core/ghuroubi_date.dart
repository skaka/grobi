import 'package:hijri/hijri_calendar.dart';

import '../models/day_times.dart';
import 'date_utils.dart';
import 'format_utils.dart';
import 'ghuroubi_clock.dart';

/// التاريخ الميلادي **الغروبي**: اليوم يبدأ عند الغروب، فبعد غروب [todaySunset]
/// نتقدّم يوماً تقويمياً واحداً (لأن اليوم الإسلامي الجديد قد بدأ).
DateTime ghuroubiCivilDate(DateTime now, DateTime todaySunset) {
  final base = dateOnly(now);
  return now.isBefore(todaySunset) ? base : addDays(base, 1);
}

/// التاريخ الهجري الغروبي من التاريخ الميلادي الغروبي، مع تعديل يدوي
/// [adjustDays] (±يوم) ليطابق رؤية أم القرى المحلية.
HijriCalendar ghuroubiHijri(DateTime ghuroubiCivil, int adjustDays) {
  return HijriCalendar.fromDate(addDays(ghuroubiCivil, adjustDays));
}

/// اسم اليوم الإسلامي للحظة [now]، و[today] مواقيت يومها التقويمي. الليل يسبق
/// النهار: من مغرب الخميس حتى فجر الجمعة «ليلة الجمعة»، ثم «الجمعة» حتى مغربها —
/// فلا يظهر «الخميس» بجوار تاريخ الجمعة الغروبي بعد الغروب.
String ghuroubiDayName(DateTime now, DayTimes today) {
  if (!now.isBefore(today.maghrib)) return nightOf(addDays(now, 1).weekday);
  if (now.isBefore(today.fajr)) return nightOf(now.weekday);
  return weekdayName(now.weekday);
}

/// ما تحتاجه الساعة الغروبية حول لحظة واحدة: مواقيت الأمس/اليوم/الغد، والساعة،
/// والتاريخ الميلادي الغروبي، والغروب القادم.
class GhuroubiDay {
  final DayTimes yesterday;
  final DayTimes today;
  final DayTimes tomorrow;
  final GhuroubiClock clock;
  final DateTime civilDate;
  final DateTime nextSunset;

  const GhuroubiDay({
    required this.yesterday,
    required this.today,
    required this.tomorrow,
    required this.clock,
    required this.civilDate,
    required this.nextSunset,
  });
}

/// يبني [GhuroubiDay] للحظة [now]. [timesFor] يُرجِع مواقيت يوم ميلادي (بلا وقت)
/// — يُحقَن كي تُختبر هذه الدالة بمواقيت حقيقية تحت أي منطقة زمنية.
///
/// الأمس والغد يُحسبان بأيام **تقويمية**: في يوم انتقال الساعة (23/25 ساعة) كانت
/// إضافة 24 ساعة تُعيد اليوم نفسه «غداً»، فينهار عدّاد الغروب ولا يتقدّم التاريخ.
GhuroubiDay ghuroubiDayAt(
    DateTime now, DayTimes Function(DateTime date) timesFor) {
  final today0 = dateOnly(now);
  final yesterday = timesFor(addDays(today0, -1));
  final today = timesFor(today0);
  final tomorrow = timesFor(addDays(today0, 1));

  final clock = GhuroubiClock.at(
    now: now,
    yesterdayMaghrib: yesterday.maghrib,
    todaySunrise: today.sunrise,
    todayMaghrib: today.maghrib,
    tomorrowMaghrib: tomorrow.maghrib,
  );

  return GhuroubiDay(
    yesterday: yesterday,
    today: today,
    tomorrow: tomorrow,
    clock: clock,
    civilDate: ghuroubiCivilDate(now, today.maghrib),
    nextSunset: now.isBefore(today.maghrib) ? today.maghrib : tomorrow.maghrib,
  );
}
