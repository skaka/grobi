// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'التوقيت الغروبي';

  @override
  String get tabClock => 'الساعة';

  @override
  String get tabPrayers => 'المواقيت';

  @override
  String get tabQibla => 'القبلة';

  @override
  String get tabCalendar => 'التقويم';

  @override
  String get tabEvents => 'المناسبات';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get locationRationaleTitle => 'موقعك لحساب المواقيت';

  @override
  String get locationRationaleBody =>
      'يحسب التطبيق مواقيت الصلاة ووقت الغروب واتجاه القبلة لموقعك بالضبط. يبقى موقعك على جهازك ولا يُرسَل إلى أي خادم.\n\nويمكنك بدلاً من ذلك اختيار مدينتك يدوياً.';

  @override
  String get notNow => 'ليس الآن';

  @override
  String get pickCity => 'اختيار مدينة';

  @override
  String get allow => 'السماح';

  @override
  String get solarTime => 'التوقيت الزوالي';

  @override
  String get civilTime => 'التوقيت المدني';

  @override
  String untilNextSunset(String duration) {
    return 'بقي للغروب القادم: $duration';
  }

  @override
  String get defaultLocationBanner =>
      'الموقع غير محدّد — تُعرض مواقيت مكة المكرمة. حدّد موقعك لمواقيت مدينتك.';

  @override
  String get setLocationShort => 'تحديد';

  @override
  String get faceNight => 'ليل';

  @override
  String get faceDay => 'نهار';

  @override
  String get meccaName => 'مكة المكرمة';

  @override
  String sourceFallback(String city) {
    return 'افتراضي ($city)';
  }

  @override
  String get sourceGps => 'موقع GPS';

  @override
  String get sourceManual => 'موقع يدوي';

  @override
  String get prayerTimesTitle => 'مواقيت الصلاة';

  @override
  String nextPrayer(String name) {
    return 'الصلاة القادمة: $name';
  }

  @override
  String get colGhuroubi => 'غروبي';

  @override
  String get colZawali => 'زوالي';

  @override
  String get colCivil => 'مدني';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String get noMagnetometer =>
      'جهازك لا يحتوي حسّاساً مغناطيسياً للبوصلة، لذا نعرض اتجاه القبلة رقمياً (الشمال للأعلى).';

  @override
  String get facingQibla => 'أنت تواجه القبلة';

  @override
  String get turnDevice => 'أدِر جهازك حتى يشير السهم للأعلى';

  @override
  String get magneticNorthNote =>
      'اتجاه مغناطيسي — قد يختلف بضع درجات عن الشمال الحقيقي';

  @override
  String trueNorthNote(String degrees, String direction) {
    return 'الشمال الحقيقي • الانحراف المغناطيسي $degrees° $direction';
  }

  @override
  String get directionEast => 'شرقاً';

  @override
  String get directionWest => 'غرباً';

  @override
  String get northUp => 'الشمال للأعلى ↑';

  @override
  String get calibrationHint =>
      'تشويش مغناطيسي: ابتعد عن المعادن والمغانط (كغطاء الجوال)، ثم حرّك الجهاز في الهواء على شكل الرقم ٨ لمعايرة البوصلة.';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees° من الشمال';
  }

  @override
  String get distanceToKaaba => 'المسافة إلى الكعبة';

  @override
  String kilometers(String value) {
    return '$value كم';
  }

  @override
  String get setYourLocation => 'حدّد موقعك';

  @override
  String get changeMyLocation => 'تغيير موقعي';

  @override
  String get calendarHint =>
      'الرقم الكبير: هجري • الصغير: ميلادي — استخدم الأسهم لتغيير الشهر';

  @override
  String get eventsTitle => 'المناسبات والإعلانات';

  @override
  String get eventsSubtitle =>
      'إعلانات دخول رمضان والأعياد والسنة الهجرية حسب دولتك';

  @override
  String get syncing => 'جارٍ المزامنة…';

  @override
  String get syncNow => 'مزامنة الإعلانات الآن';

  @override
  String errorWith(String error) {
    return 'خطأ: $error';
  }

  @override
  String get noAnnouncements =>
      'لا توجد إعلانات بعد — اختر الدولة من الإعدادات ثم زامِن.';

  @override
  String get syncPickCountry => 'حدّد الدولة أولاً';

  @override
  String syncNewAlerts(String count) {
    return 'تنبيهات جديدة: $count';
  }

  @override
  String get syncNothingNew => 'تمت المزامنة — لا جديد';

  @override
  String syncFailed(String error) {
    return 'تعذّرت المزامنة: $error';
  }

  @override
  String get eventHijriNewYear => 'رأس السنة الهجرية';

  @override
  String get eventShaban => 'دخول شعبان';

  @override
  String get eventRamadan => 'دخول رمضان';

  @override
  String get eventEidFitr => 'عيد الفطر';

  @override
  String get eventDhulHijjah => 'دخول ذي الحجة';

  @override
  String monthStart(String month) {
    return 'بداية $month';
  }

  @override
  String get notifBodyHijriNewYear => 'ثبتت غُرّة محرّم — كل عام وأنتم بخير.';

  @override
  String get notifBodyShaban => 'دخل شهر شعبان — استعداداً لرمضان.';

  @override
  String get notifBodyRamadan => 'ثبت دخول شهر رمضان المبارك — رمضان كريم.';

  @override
  String get notifBodyEidFitr => 'ثبت شوّال وعيد الفطر — عيد مبارك.';

  @override
  String get notifBodyDhulHijjah =>
      'دخل شهر ذي الحجة — عرفة وعيد الأضحى قريباً.';

  @override
  String get channelName => 'المناسبات الإسلامية';

  @override
  String get channelDescription => 'إشعارات دخول رمضان والأعياد والسنة الهجرية';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionLocation => 'الموقع';

  @override
  String get change => 'تغيير';

  @override
  String get sectionPrayerTimes => 'المواقيت';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get manualHijriAdjust => 'تعديل يدوي للتاريخ الهجري';

  @override
  String get doubleCorrectionWarning =>
      'تقويم دولتك مُصحَّح من إعلانات الرؤية، وهذا التعديل يُضاف فوقه فيُزيح التاريخ مرّتين.';

  @override
  String get reset => 'تصفير';

  @override
  String get manualAdjustHint =>
      'احتياطي: اتركه صفراً ما دامت دولتك محدّدة في «المناسبات».';

  @override
  String get sectionEvents => 'المناسبات';

  @override
  String get country => 'الدولة';

  @override
  String get choose => 'اختر';

  @override
  String get sectionAdvanced => 'متقدّم';

  @override
  String get horizonTitle => 'الارتفاع فوق الأفق المحيط';

  @override
  String get horizonDescription =>
      'لمن يطلّ على أفق منخفض (جبل فوق البحر). يؤخّر المغرب ويقدّم الشروق — اتركه معطّلاً لمطابقة أم القرى.';

  @override
  String get off => 'معطّل';

  @override
  String get horizonDialogTitle => 'الارتفاع فوق الأفق المحيط (متر)';

  @override
  String get horizonDialogHint => 'مثال: 300 — لا ارتفاع المدينة عن البحر';

  @override
  String get turnOff => 'تعطيل';

  @override
  String get save => 'حفظ';

  @override
  String get sectionInfo => 'معلومات';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get languageDevice => 'لغة الجهاز';

  @override
  String meters(String value) {
    return '$value م';
  }

  @override
  String get methodUmmAlQura => 'أم القرى (السعودية)';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية (كراتشي)';

  @override
  String get methodNorthAmerica => 'أمريكا الشمالية (ISNA)';

  @override
  String get methodDubai => 'دبي';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodMoonsighting => 'لجنة رؤية الهلال';

  @override
  String get methodSingapore => 'سنغافورة';

  @override
  String get methodTurkey => 'تركيا (ديانت)';

  @override
  String get methodTehran => 'طهران';

  @override
  String get pickerTitle => 'تحديد الموقع';

  @override
  String currentLocation(String label) {
    return 'الحالي: $label';
  }

  @override
  String get useGps => 'استخدام موقعي الحالي (GPS)';

  @override
  String get orPickCityIn => 'أو اختر مدينة في';

  @override
  String get noCitiesForCountry =>
      'لا مدن مضمَّنة لهذه الدولة بعد — أدخل الإحداثيات يدوياً.';

  @override
  String get enterCoordinates => 'إدخال الإحداثيات يدوياً';

  @override
  String get openAppSettings => 'الإعدادات';

  @override
  String get turnOn => 'تفعيل';

  @override
  String get coordinatesTitle => 'الإحداثيات';

  @override
  String get latitudeLabel => 'خط العرض (شمال +)';

  @override
  String get longitudeLabel => 'خط الطول (شرق +)';

  @override
  String get latitudeHint => 'مثال: 24.7136';

  @override
  String get longitudeHint => 'مثال: 46.6753';

  @override
  String get latitudeRange => 'خط العرض بين −٩٠ و٩٠';

  @override
  String get longitudeRange => 'خط الطول بين −١٨٠ و١٨٠';

  @override
  String get cancel => 'إلغاء';

  @override
  String get gpsServiceDisabled =>
      'خدمة الموقع متوقّفة في الجهاز — فعّلها أو اختر مدينتك.';

  @override
  String get gpsDenied => 'لم يُمنح إذن الموقع — يمكنك اختيار مدينتك يدوياً.';

  @override
  String get gpsDeniedForever =>
      'إذن الموقع مرفوض نهائياً — فعّله من إعدادات التطبيق أو اختر مدينتك.';

  @override
  String get gpsUnavailable =>
      'تعذّر تحديد الموقع الآن — حاول لاحقاً أو اختر مدينتك.';

  @override
  String get aboutTitle => 'عن التطبيق';

  @override
  String versionBuild(String version, String build) {
    return 'الإصدار $version  •  بناء $build';
  }

  @override
  String get aboutDescription =>
      'التوقيت الغروبي تطبيق يعرض الساعة الغروبية والتقويم الهجري ومواقيت الصلاة بحساب فلكي دقيق لموقعك، مع اتجاه القبلة والمناسبات الإسلامية.';

  @override
  String get contactSection => 'التواصل';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get technicalInfo => 'معلومات فنية';

  @override
  String get identifier => 'المعرّف';

  @override
  String get gregorianDateLabel => 'التاريخ الميلادي';

  @override
  String get hijriDateLabel => 'التاريخ الهجري';

  @override
  String get outOfRange => 'خارج المدى المدعوم';

  @override
  String get converterTitle => 'تحويل التاريخ';

  @override
  String get gregToHijri => 'ميلادي إلى هجري';

  @override
  String get hijriToGreg => 'هجري إلى ميلادي';

  @override
  String get durationTitle => 'حساب المدة / العمر';

  @override
  String get fromLabel => 'من';

  @override
  String get toLabel => 'إلى';

  @override
  String get setToToday => 'اجعل «إلى» اليوم';

  @override
  String get gregorianCalendar => 'ميلادي';

  @override
  String get hijriCalendar => 'هجري';

  @override
  String totalDaysWeeks(String days, String weeks) {
    return 'الإجمالي: $days يوم • $weeks أسبوع';
  }

  @override
  String get unitYears => 'سنة';

  @override
  String get unitMonths => 'شهر';

  @override
  String get unitDays => 'يوم';

  @override
  String get pickHijriDate => 'اختر التاريخ الهجري';

  @override
  String get dayHeader => 'اليوم';

  @override
  String get monthHeader => 'الشهر';

  @override
  String get yearHeader => 'السنة';

  @override
  String get confirm => 'تأكيد';
}
