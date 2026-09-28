import 'package:adhan/adhan.dart';

import '../models/day_times.dart';
import '../models/location_data.dart';
import 'date_utils.dart';
import 'elevation.dart';
import 'umm_alqura_corrections.dart';

/// يحسب مواقيت يوم [date] لموقع [loc] بطريقة [method].
///
/// **افتراضياً لا تصحيح للارتفاع**، فتطابق النتيجة `adhan` وجداول أم القرى الرسمية
/// بالدقيقة: الجداول تفترض أفقاً عند مستوى الراصد، وهذا حال معظم المدن (هضاب أفقها
/// بارتفاعها). تطبيق ارتفاع GPS كاملاً كان يؤخّر المغرب 4–7 دقائق عن الرسمي.
///
/// [horizonHeight] (خيار متقدّم، 0 = معطّل) = ارتفاع الراصد **فوق الأفق المحيط**
/// (جبل يطلّ على البحر مثلاً). انخفاض الأفق المرئي يخصّ **رؤية قرص الشمس** فقط:
/// **الشروق `−Δt` والمغرب `+Δt`**؛ أمّا الفجر والعشاء (زاويتا شفق) والعصر (نسبة
/// ظلّ) والظهر (الزوال) فلا تتأثّر، والعشاء الفاصلي (أم القرى/قطر) يتبع المغرب.
/// ولأن `adhan` يُخرج دقائق كاملة، نقرّب الناتج احتياطاً: بداية الصلاة للأعلى
/// والشروق (نهاية وقت الفجر) للأسفل.
///
/// وفي أم القرى يكون العشاء = المغرب + 90 دقيقة، **و120 دقيقة في رمضان** رسمياً؛
/// نحدِّد رمضان من التاريخ الهجري لليلة التي تبدأ بمغرب [date] (مع [hijriAdjust]).
DayTimes computeDayTimes(
  LocationData loc,
  DateTime date,
  CalculationMethod method, {
  int hijriAdjust = 0,
  Map<int, int> adjustments = const {},
  double horizonHeight = 0,
}) {
  final coords = Coordinates(loc.latitude, loc.longitude);
  final params = method.getParameters();
  final pt = PrayerTimes(coords, DateComponents.from(date), params);

  final deltaMinutes = elevationDeltaMinutes(loc.latitude, date, horizonHeight);
  final dt = Duration(milliseconds: (deltaMinutes * 60000).round());

  // العشاء الفاصلي (ishaInterval > 0) مرتبط بالمغرب فيأخذ إزاحته؛ والزاوي لا.
  final ishaDt = params.ishaInterval > 0 ? dt : Duration.zero;

  // عشاء رمضان في أم القرى: +30 دقيقة (90 ⇐ 120). العشاء يقع بعد مغرب [date]
  // فيخصّ اليوم الإسلامي الذي يبدأ بذلك المغرب (= هجري اليوم التقويمي التالي).
  var ramadanExtra = Duration.zero;
  if (method == CalculationMethod.umm_al_qura) {
    final islamicEvening = correctedHijri(addDays(date, 1), adjustments,
        manualAdjust: hijriAdjust);
    if (islamicEvening.hMonth == 9) ramadanExtra = const Duration(minutes: 30);
  }

  return DayTimes(
    fajr: pt.fajr, // زاوية شفق — لا تتأثّر بالارتفاع
    sunrise: _floorMinute(pt.sunrise.subtract(dt)),
    dhuhr: pt.dhuhr, // الزوال — لا يتأثّر بالارتفاع
    asr: pt.asr, // نسبة ظلّ — لا تتأثّر بالارتفاع
    maghrib: _ceilMinute(pt.maghrib.add(dt)),
    isha: _ceilMinute(pt.isha.add(ishaDt)).add(ramadanExtra),
  );
}

/// يقطع الثواني (للشروق: لا نؤخّر نهاية وقت الفجر).
DateTime _floorMinute(DateTime t) => t.subtract(Duration(
    seconds: t.second,
    milliseconds: t.millisecond,
    microseconds: t.microsecond));

/// يرفع إلى الدقيقة التالية إن وُجدت ثوانٍ (لبداية الصلاة: لا نقدّمها).
DateTime _ceilMinute(DateTime t) {
  final floor = _floorMinute(t);
  return floor == t ? t : floor.add(const Duration(minutes: 1));
}

/// طرق الحساب المعروضة في الإعدادات (أم القرى أولاً = الافتراضي).
const List<CalculationMethod> supportedMethods = [
  CalculationMethod.umm_al_qura,
  CalculationMethod.muslim_world_league,
  CalculationMethod.egyptian,
  CalculationMethod.karachi,
  CalculationMethod.north_america,
  CalculationMethod.dubai,
  CalculationMethod.qatar,
  CalculationMethod.kuwait,
  CalculationMethod.moon_sighting_committee,
  CalculationMethod.singapore,
  CalculationMethod.turkey,
  CalculationMethod.tehran,
];
