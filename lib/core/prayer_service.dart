import 'package:adhan/adhan.dart';

import '../models/day_times.dart';
import '../models/location_data.dart';
import 'elevation.dart';
import 'umm_alqura_corrections.dart';

/// يحسب مواقيت يوم [date] لموقع [loc] بطريقة [method]، ثم يطبّق تصحيح الارتفاع.
///
/// تصحيح الارتفاع (انخفاض الأفق المرئي) يخصّ **رؤية قرص الشمس عند الأفق** فقط،
/// أي **الشروق `−Δt` والمغرب `+Δt`**. أمّا الفجر والعشاء (زاويتا شفقٍ تُقاسان من
/// الأفق الفلكي) والعصر (نسبة ظلٍّ) والظهر (لحظة الزوال) فلا تتأثّر بالارتفاع —
/// وهذا هو المعتمد في تقويم أم القرى. والعشاء الفاصلي (أم القرى/قطر) يتبع المغرب
/// فيأخذ نفس إزاحته تلقائياً.
///
/// وفي أم القرى يكون العشاء = المغرب + 90 دقيقة، **و120 دقيقة في رمضان** رسمياً؛
/// نحدِّد رمضان من التاريخ الهجري لليلة التي تبدأ بمغرب [date] (مع [hijriAdjust]).
///
/// مبني على حزمة `adhan` (تُخرج أوقاتاً محلية)، والتي لا تدعم الارتفاع، فنصحّحه
/// عبر [elevationDeltaMinutes].
DayTimes computeDayTimes(
  LocationData loc,
  DateTime date,
  CalculationMethod method, {
  int hijriAdjust = 0,
  Map<int, int> adjustments = const {},
}) {
  final coords = Coordinates(loc.latitude, loc.longitude);
  final params = method.getParameters();
  final pt = PrayerTimes(coords, DateComponents.from(date), params);

  final deltaMinutes = elevationDeltaMinutes(loc.latitude, date, loc.altitude);
  final dt = Duration(milliseconds: (deltaMinutes * 60000).round());

  // العشاء الفاصلي (ishaInterval > 0) مرتبط بالمغرب فيأخذ إزاحته؛ والزاوي لا.
  final ishaDt = params.ishaInterval > 0 ? dt : Duration.zero;

  // عشاء رمضان في أم القرى: +30 دقيقة (90 ⇐ 120). العشاء يقع بعد مغرب [date]
  // فيخصّ اليوم الإسلامي الذي يبدأ بذلك المغرب (≈ هجري اليوم الميلادي التالي).
  var ramadanExtra = Duration.zero;
  if (method == CalculationMethod.umm_al_qura) {
    final islamicEvening = correctedHijri(
        date.add(const Duration(days: 1)), adjustments,
        manualAdjust: hijriAdjust);
    if (islamicEvening.hMonth == 9) ramadanExtra = const Duration(minutes: 30);
  }

  return DayTimes(
    fajr: pt.fajr, // زاوية شفق — لا تتأثّر بالارتفاع
    sunrise: pt.sunrise.subtract(dt),
    dhuhr: pt.dhuhr, // الزوال — لا يتأثّر بالارتفاع
    asr: pt.asr, // نسبة ظلّ — لا تتأثّر بالارتفاع
    maghrib: pt.maghrib.add(dt),
    isha: pt.isha.add(ishaDt).add(ramadanExtra),
  );
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

String calculationMethodArabicName(CalculationMethod method) {
  switch (method) {
    case CalculationMethod.umm_al_qura:
      return 'أم القرى (السعودية)';
    case CalculationMethod.muslim_world_league:
      return 'رابطة العالم الإسلامي';
    case CalculationMethod.egyptian:
      return 'الهيئة المصرية العامة للمساحة';
    case CalculationMethod.karachi:
      return 'جامعة العلوم الإسلامية (كراتشي)';
    case CalculationMethod.north_america:
      return 'أمريكا الشمالية (ISNA)';
    case CalculationMethod.dubai:
      return 'دبي';
    case CalculationMethod.qatar:
      return 'قطر';
    case CalculationMethod.kuwait:
      return 'الكويت';
    case CalculationMethod.moon_sighting_committee:
      return 'لجنة رؤية الهلال';
    case CalculationMethod.singapore:
      return 'سنغافورة';
    case CalculationMethod.turkey:
      return 'تركيا (ديانت)';
    case CalculationMethod.tehran:
      return 'طهران';
    default:
      return method.name;
  }
}
