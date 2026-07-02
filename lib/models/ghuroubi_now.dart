import 'package:hijri/hijri_calendar.dart';

import '../core/ghuroubi_clock.dart';
import '../core/solar_time.dart';
import 'day_times.dart';

/// لقطة للّحظة الحالية بالنظام الغروبي (تُحدَّث كل دقيقة؛ العدّاد التنازلي يُحدَّث
/// كل ثانية عبر [nextSunset] منفصلاً كي لا نُعيد بناء كل شيء كل ثانية).
class GhuroubiNow {
  final DateTime now;
  final GhuroubiClock clock;
  final DateTime ghuroubiCivilDate; // التاريخ الميلادي الغروبي
  final HijriCalendar hijri; // التاريخ الهجري الغروبي
  final SolarTimeOfDay solar; // التوقيت الشمسي الحقيقي
  final DayTimes today; // مواقيت اليوم (للعرض)
  final DateTime nextSunset; // الغروب القادم (لعدّاد تنازلي ثانوي مستقل)

  const GhuroubiNow({
    required this.now,
    required this.clock,
    required this.ghuroubiCivilDate,
    required this.hijri,
    required this.solar,
    required this.today,
    required this.nextSunset,
  });
}
