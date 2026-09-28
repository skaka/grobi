import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوقيت الغروبي'**
  String get appTitle;

  /// No description provided for @tabClock.
  ///
  /// In ar, this message translates to:
  /// **'الساعة'**
  String get tabClock;

  /// No description provided for @tabPrayers.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت'**
  String get tabPrayers;

  /// No description provided for @tabQibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get tabQibla;

  /// No description provided for @tabCalendar.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get tabCalendar;

  /// No description provided for @tabEvents.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات'**
  String get tabEvents;

  /// No description provided for @settingsTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTooltip;

  /// No description provided for @locationRationaleTitle.
  ///
  /// In ar, this message translates to:
  /// **'موقعك لحساب المواقيت'**
  String get locationRationaleTitle;

  /// No description provided for @locationRationaleBody.
  ///
  /// In ar, this message translates to:
  /// **'يحسب التطبيق مواقيت الصلاة ووقت الغروب واتجاه القبلة لموقعك بالضبط. يبقى موقعك على جهازك ولا يُرسَل إلى أي خادم.\n\nويمكنك بدلاً من ذلك اختيار مدينتك يدوياً.'**
  String get locationRationaleBody;

  /// No description provided for @notNow.
  ///
  /// In ar, this message translates to:
  /// **'ليس الآن'**
  String get notNow;

  /// No description provided for @pickCity.
  ///
  /// In ar, this message translates to:
  /// **'اختيار مدينة'**
  String get pickCity;

  /// No description provided for @allow.
  ///
  /// In ar, this message translates to:
  /// **'السماح'**
  String get allow;

  /// No description provided for @solarTime.
  ///
  /// In ar, this message translates to:
  /// **'التوقيت الزوالي'**
  String get solarTime;

  /// No description provided for @civilTime.
  ///
  /// In ar, this message translates to:
  /// **'التوقيت المدني'**
  String get civilTime;

  /// No description provided for @untilNextSunset.
  ///
  /// In ar, this message translates to:
  /// **'بقي للغروب القادم: {duration}'**
  String untilNextSunset(String duration);

  /// No description provided for @defaultLocationBanner.
  ///
  /// In ar, this message translates to:
  /// **'الموقع غير محدّد — تُعرض مواقيت مكة المكرمة. حدّد موقعك لمواقيت مدينتك.'**
  String get defaultLocationBanner;

  /// No description provided for @setLocationShort.
  ///
  /// In ar, this message translates to:
  /// **'تحديد'**
  String get setLocationShort;

  /// No description provided for @faceNight.
  ///
  /// In ar, this message translates to:
  /// **'ليل'**
  String get faceNight;

  /// No description provided for @faceDay.
  ///
  /// In ar, this message translates to:
  /// **'نهار'**
  String get faceDay;

  /// No description provided for @meccaName.
  ///
  /// In ar, this message translates to:
  /// **'مكة المكرمة'**
  String get meccaName;

  /// No description provided for @sourceFallback.
  ///
  /// In ar, this message translates to:
  /// **'افتراضي ({city})'**
  String sourceFallback(String city);

  /// No description provided for @sourceGps.
  ///
  /// In ar, this message translates to:
  /// **'موقع GPS'**
  String get sourceGps;

  /// No description provided for @sourceManual.
  ///
  /// In ar, this message translates to:
  /// **'موقع يدوي'**
  String get sourceManual;

  /// No description provided for @prayerTimesTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get prayerTimesTitle;

  /// No description provided for @nextPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة: {name}'**
  String nextPrayer(String name);

  /// No description provided for @colGhuroubi.
  ///
  /// In ar, this message translates to:
  /// **'غروبي'**
  String get colGhuroubi;

  /// No description provided for @colZawali.
  ///
  /// In ar, this message translates to:
  /// **'زوالي'**
  String get colZawali;

  /// No description provided for @colCivil.
  ///
  /// In ar, this message translates to:
  /// **'مدني'**
  String get colCivil;

  /// No description provided for @prayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerIsha;

  /// No description provided for @qiblaTitle.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qiblaTitle;

  /// No description provided for @noMagnetometer.
  ///
  /// In ar, this message translates to:
  /// **'جهازك لا يحتوي حسّاساً مغناطيسياً للبوصلة، لذا نعرض اتجاه القبلة رقمياً (الشمال للأعلى).'**
  String get noMagnetometer;

  /// No description provided for @facingQibla.
  ///
  /// In ar, this message translates to:
  /// **'أنت تواجه القبلة'**
  String get facingQibla;

  /// No description provided for @turnDevice.
  ///
  /// In ar, this message translates to:
  /// **'أدِر جهازك حتى يشير السهم للأعلى'**
  String get turnDevice;

  /// No description provided for @magneticNorthNote.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه مغناطيسي — قد يختلف بضع درجات عن الشمال الحقيقي'**
  String get magneticNorthNote;

  /// No description provided for @trueNorthNote.
  ///
  /// In ar, this message translates to:
  /// **'الشمال الحقيقي • الانحراف المغناطيسي {degrees}° {direction}'**
  String trueNorthNote(String degrees, String direction);

  /// No description provided for @directionEast.
  ///
  /// In ar, this message translates to:
  /// **'شرقاً'**
  String get directionEast;

  /// No description provided for @directionWest.
  ///
  /// In ar, this message translates to:
  /// **'غرباً'**
  String get directionWest;

  /// No description provided for @northUp.
  ///
  /// In ar, this message translates to:
  /// **'الشمال للأعلى ↑'**
  String get northUp;

  /// No description provided for @calibrationHint.
  ///
  /// In ar, this message translates to:
  /// **'تشويش مغناطيسي: ابتعد عن المعادن والمغانط (كغطاء الجوال)، ثم حرّك الجهاز في الهواء على شكل الرقم ٨ لمعايرة البوصلة.'**
  String get calibrationHint;

  /// No description provided for @qiblaDirection.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة'**
  String get qiblaDirection;

  /// No description provided for @degreesFromNorth.
  ///
  /// In ar, this message translates to:
  /// **'{degrees}° من الشمال'**
  String degreesFromNorth(String degrees);

  /// No description provided for @distanceToKaaba.
  ///
  /// In ar, this message translates to:
  /// **'المسافة إلى الكعبة'**
  String get distanceToKaaba;

  /// No description provided for @kilometers.
  ///
  /// In ar, this message translates to:
  /// **'{value} كم'**
  String kilometers(String value);

  /// No description provided for @setYourLocation.
  ///
  /// In ar, this message translates to:
  /// **'حدّد موقعك'**
  String get setYourLocation;

  /// No description provided for @changeMyLocation.
  ///
  /// In ar, this message translates to:
  /// **'تغيير موقعي'**
  String get changeMyLocation;

  /// No description provided for @calendarHint.
  ///
  /// In ar, this message translates to:
  /// **'الرقم الكبير: هجري • الصغير: ميلادي — استخدم الأسهم لتغيير الشهر'**
  String get calendarHint;

  /// No description provided for @eventsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات والإعلانات'**
  String get eventsTitle;

  /// No description provided for @eventsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إعلانات دخول رمضان والأعياد والسنة الهجرية حسب دولتك'**
  String get eventsSubtitle;

  /// No description provided for @syncing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ المزامنة…'**
  String get syncing;

  /// No description provided for @syncNow.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة الإعلانات الآن'**
  String get syncNow;

  /// No description provided for @errorWith.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {error}'**
  String errorWith(String error);

  /// No description provided for @noAnnouncements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات بعد — اختر الدولة من الإعدادات ثم زامِن.'**
  String get noAnnouncements;

  /// No description provided for @syncPickCountry.
  ///
  /// In ar, this message translates to:
  /// **'حدّد الدولة أولاً'**
  String get syncPickCountry;

  /// No description provided for @syncNewAlerts.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات جديدة: {count}'**
  String syncNewAlerts(String count);

  /// No description provided for @syncNothingNew.
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة — لا جديد'**
  String get syncNothingNew;

  /// No description provided for @syncFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّرت المزامنة: {error}'**
  String syncFailed(String error);

  /// No description provided for @eventHijriNewYear.
  ///
  /// In ar, this message translates to:
  /// **'رأس السنة الهجرية'**
  String get eventHijriNewYear;

  /// No description provided for @eventShaban.
  ///
  /// In ar, this message translates to:
  /// **'دخول شعبان'**
  String get eventShaban;

  /// No description provided for @eventRamadan.
  ///
  /// In ar, this message translates to:
  /// **'دخول رمضان'**
  String get eventRamadan;

  /// No description provided for @eventEidFitr.
  ///
  /// In ar, this message translates to:
  /// **'عيد الفطر'**
  String get eventEidFitr;

  /// No description provided for @eventDhulHijjah.
  ///
  /// In ar, this message translates to:
  /// **'دخول ذي الحجة'**
  String get eventDhulHijjah;

  /// No description provided for @monthStart.
  ///
  /// In ar, this message translates to:
  /// **'بداية {month}'**
  String monthStart(String month);

  /// No description provided for @notifBodyHijriNewYear.
  ///
  /// In ar, this message translates to:
  /// **'ثبتت غُرّة محرّم — كل عام وأنتم بخير.'**
  String get notifBodyHijriNewYear;

  /// No description provided for @notifBodyShaban.
  ///
  /// In ar, this message translates to:
  /// **'دخل شهر شعبان — استعداداً لرمضان.'**
  String get notifBodyShaban;

  /// No description provided for @notifBodyRamadan.
  ///
  /// In ar, this message translates to:
  /// **'ثبت دخول شهر رمضان المبارك — رمضان كريم.'**
  String get notifBodyRamadan;

  /// No description provided for @notifBodyEidFitr.
  ///
  /// In ar, this message translates to:
  /// **'ثبت شوّال وعيد الفطر — عيد مبارك.'**
  String get notifBodyEidFitr;

  /// No description provided for @notifBodyDhulHijjah.
  ///
  /// In ar, this message translates to:
  /// **'دخل شهر ذي الحجة — عرفة وعيد الأضحى قريباً.'**
  String get notifBodyDhulHijjah;

  /// No description provided for @channelName.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات الإسلامية'**
  String get channelName;

  /// No description provided for @channelDescription.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات دخول رمضان والأعياد والسنة الهجرية'**
  String get channelDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @sectionLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get sectionLocation;

  /// No description provided for @change.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get change;

  /// No description provided for @sectionPrayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت'**
  String get sectionPrayerTimes;

  /// No description provided for @calculationMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get calculationMethod;

  /// No description provided for @manualHijriAdjust.
  ///
  /// In ar, this message translates to:
  /// **'تعديل يدوي للتاريخ الهجري'**
  String get manualHijriAdjust;

  /// No description provided for @doubleCorrectionWarning.
  ///
  /// In ar, this message translates to:
  /// **'تقويم دولتك مُصحَّح من إعلانات الرؤية، وهذا التعديل يُضاف فوقه فيُزيح التاريخ مرّتين.'**
  String get doubleCorrectionWarning;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'تصفير'**
  String get reset;

  /// No description provided for @manualAdjustHint.
  ///
  /// In ar, this message translates to:
  /// **'احتياطي: اتركه صفراً ما دامت دولتك محدّدة في «المناسبات».'**
  String get manualAdjustHint;

  /// No description provided for @sectionEvents.
  ///
  /// In ar, this message translates to:
  /// **'المناسبات'**
  String get sectionEvents;

  /// No description provided for @country.
  ///
  /// In ar, this message translates to:
  /// **'الدولة'**
  String get country;

  /// No description provided for @choose.
  ///
  /// In ar, this message translates to:
  /// **'اختر'**
  String get choose;

  /// No description provided for @sectionAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدّم'**
  String get sectionAdvanced;

  /// No description provided for @horizonTitle.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع فوق الأفق المحيط'**
  String get horizonTitle;

  /// No description provided for @horizonDescription.
  ///
  /// In ar, this message translates to:
  /// **'لمن يطلّ على أفق منخفض (جبل فوق البحر). يؤخّر المغرب ويقدّم الشروق — اتركه معطّلاً لمطابقة أم القرى.'**
  String get horizonDescription;

  /// No description provided for @off.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get off;

  /// No description provided for @horizonDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'الارتفاع فوق الأفق المحيط (متر)'**
  String get horizonDialogTitle;

  /// No description provided for @horizonDialogHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 300 — لا ارتفاع المدينة عن البحر'**
  String get horizonDialogHint;

  /// No description provided for @turnOff.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get turnOff;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @sectionInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات'**
  String get sectionInfo;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutApp;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In ar, this message translates to:
  /// **'لغة الجهاز'**
  String get languageDevice;

  /// No description provided for @meters.
  ///
  /// In ar, this message translates to:
  /// **'{value} م'**
  String meters(String value);

  /// No description provided for @methodUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى (السعودية)'**
  String get methodUmmAlQura;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية العامة للمساحة'**
  String get methodEgyptian;

  /// No description provided for @methodKarachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية (كراتشي)'**
  String get methodKarachi;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In ar, this message translates to:
  /// **'أمريكا الشمالية (ISNA)'**
  String get methodNorthAmerica;

  /// No description provided for @methodDubai.
  ///
  /// In ar, this message translates to:
  /// **'دبي'**
  String get methodDubai;

  /// No description provided for @methodQatar.
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get methodQatar;

  /// No description provided for @methodKuwait.
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get methodKuwait;

  /// No description provided for @methodMoonsighting.
  ///
  /// In ar, this message translates to:
  /// **'لجنة رؤية الهلال'**
  String get methodMoonsighting;

  /// No description provided for @methodSingapore.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة'**
  String get methodSingapore;

  /// No description provided for @methodTurkey.
  ///
  /// In ar, this message translates to:
  /// **'تركيا (ديانت)'**
  String get methodTurkey;

  /// No description provided for @methodTehran.
  ///
  /// In ar, this message translates to:
  /// **'طهران'**
  String get methodTehran;

  /// No description provided for @pickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الموقع'**
  String get pickerTitle;

  /// No description provided for @currentLocation.
  ///
  /// In ar, this message translates to:
  /// **'الحالي: {label}'**
  String currentLocation(String label);

  /// No description provided for @useGps.
  ///
  /// In ar, this message translates to:
  /// **'استخدام موقعي الحالي (GPS)'**
  String get useGps;

  /// No description provided for @orPickCityIn.
  ///
  /// In ar, this message translates to:
  /// **'أو اختر مدينة في'**
  String get orPickCityIn;

  /// No description provided for @noCitiesForCountry.
  ///
  /// In ar, this message translates to:
  /// **'لا مدن مضمَّنة لهذه الدولة بعد — أدخل الإحداثيات يدوياً.'**
  String get noCitiesForCountry;

  /// No description provided for @enterCoordinates.
  ///
  /// In ar, this message translates to:
  /// **'إدخال الإحداثيات يدوياً'**
  String get enterCoordinates;

  /// No description provided for @openAppSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get openAppSettings;

  /// No description provided for @turnOn.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get turnOn;

  /// No description provided for @coordinatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإحداثيات'**
  String get coordinatesTitle;

  /// No description provided for @latitudeLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض (شمال +)'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول (شرق +)'**
  String get longitudeLabel;

  /// No description provided for @latitudeHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 24.7136'**
  String get latitudeHint;

  /// No description provided for @longitudeHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 46.6753'**
  String get longitudeHint;

  /// No description provided for @latitudeRange.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض بين −٩٠ و٩٠'**
  String get latitudeRange;

  /// No description provided for @longitudeRange.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول بين −١٨٠ و١٨٠'**
  String get longitudeRange;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @gpsServiceDisabled.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقّفة في الجهاز — فعّلها أو اختر مدينتك.'**
  String get gpsServiceDisabled;

  /// No description provided for @gpsDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُمنح إذن الموقع — يمكنك اختيار مدينتك يدوياً.'**
  String get gpsDenied;

  /// No description provided for @gpsDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض نهائياً — فعّله من إعدادات التطبيق أو اختر مدينتك.'**
  String get gpsDeniedForever;

  /// No description provided for @gpsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد الموقع الآن — حاول لاحقاً أو اختر مدينتك.'**
  String get gpsUnavailable;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutTitle;

  /// No description provided for @versionBuild.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}  •  بناء {build}'**
  String versionBuild(String version, String build);

  /// No description provided for @aboutDescription.
  ///
  /// In ar, this message translates to:
  /// **'التوقيت الغروبي تطبيق يعرض الساعة الغروبية والتقويم الهجري ومواقيت الصلاة بحساب فلكي دقيق لموقعك، مع اتجاه القبلة والمناسبات الإسلامية.'**
  String get aboutDescription;

  /// No description provided for @contactSection.
  ///
  /// In ar, this message translates to:
  /// **'التواصل'**
  String get contactSection;

  /// No description provided for @website.
  ///
  /// In ar, this message translates to:
  /// **'الموقع الإلكتروني'**
  String get website;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactUs;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @technicalInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات فنية'**
  String get technicalInfo;

  /// No description provided for @identifier.
  ///
  /// In ar, this message translates to:
  /// **'المعرّف'**
  String get identifier;

  /// No description provided for @gregorianDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الميلادي'**
  String get gregorianDateLabel;

  /// No description provided for @hijriDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الهجري'**
  String get hijriDateLabel;

  /// No description provided for @outOfRange.
  ///
  /// In ar, this message translates to:
  /// **'خارج المدى المدعوم'**
  String get outOfRange;

  /// No description provided for @converterTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحويل التاريخ'**
  String get converterTitle;

  /// No description provided for @gregToHijri.
  ///
  /// In ar, this message translates to:
  /// **'ميلادي إلى هجري'**
  String get gregToHijri;

  /// No description provided for @hijriToGreg.
  ///
  /// In ar, this message translates to:
  /// **'هجري إلى ميلادي'**
  String get hijriToGreg;

  /// No description provided for @durationTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب المدة / العمر'**
  String get durationTitle;

  /// No description provided for @fromLabel.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get toLabel;

  /// No description provided for @setToToday.
  ///
  /// In ar, this message translates to:
  /// **'اجعل «إلى» اليوم'**
  String get setToToday;

  /// No description provided for @gregorianCalendar.
  ///
  /// In ar, this message translates to:
  /// **'ميلادي'**
  String get gregorianCalendar;

  /// No description provided for @hijriCalendar.
  ///
  /// In ar, this message translates to:
  /// **'هجري'**
  String get hijriCalendar;

  /// No description provided for @totalDaysWeeks.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي: {days} يوم • {weeks} أسبوع'**
  String totalDaysWeeks(String days, String weeks);

  /// No description provided for @unitYears.
  ///
  /// In ar, this message translates to:
  /// **'سنة'**
  String get unitYears;

  /// No description provided for @unitMonths.
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get unitMonths;

  /// No description provided for @unitDays.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get unitDays;

  /// No description provided for @pickHijriDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ الهجري'**
  String get pickHijriDate;

  /// No description provided for @dayHeader.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get dayHeader;

  /// No description provided for @monthHeader.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get monthHeader;

  /// No description provided for @yearHeader.
  ///
  /// In ar, this message translates to:
  /// **'السنة'**
  String get yearHeader;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
