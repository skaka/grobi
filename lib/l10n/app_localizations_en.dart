// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ghuroubi Time';

  @override
  String get tabClock => 'Clock';

  @override
  String get tabPrayers => 'Prayers';

  @override
  String get tabQibla => 'Qibla';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabEvents => 'Events';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get locationRationaleTitle => 'Your location for prayer times';

  @override
  String get locationRationaleBody =>
      'The app calculates prayer times, sunset and the Qibla direction for your exact location. Your location stays on your device and is never sent to any server.\n\nYou can pick your city manually instead.';

  @override
  String get notNow => 'Not now';

  @override
  String get pickCity => 'Pick a city';

  @override
  String get allow => 'Allow';

  @override
  String get solarTime => 'True solar time';

  @override
  String get civilTime => 'Civil time';

  @override
  String untilNextSunset(String duration) {
    return 'Next sunset in $duration';
  }

  @override
  String get defaultLocationBanner =>
      'Location not set — showing Mecca\'s times. Set your location for your city\'s times.';

  @override
  String get setLocationShort => 'Set';

  @override
  String get faceNight => 'Night';

  @override
  String get faceDay => 'Day';

  @override
  String get meccaName => 'Mecca';

  @override
  String sourceFallback(String city) {
    return 'Default ($city)';
  }

  @override
  String get sourceGps => 'GPS location';

  @override
  String get sourceManual => 'Manual location';

  @override
  String get prayerTimesTitle => 'Prayer times';

  @override
  String nextPrayer(String name) {
    return 'Next prayer: $name';
  }

  @override
  String get colGhuroubi => 'Ghuroubi';

  @override
  String get colZawali => 'Solar';

  @override
  String get colCivil => 'Civil';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get noMagnetometer =>
      'Your device has no magnetic compass sensor, so the Qibla direction is shown numerically (north is up).';

  @override
  String get facingQibla => 'You are facing the Qibla';

  @override
  String get turnDevice => 'Turn your device until the arrow points up';

  @override
  String get magneticNorthNote =>
      'Magnetic heading — may differ from true north by a few degrees';

  @override
  String trueNorthNote(String degrees, String direction) {
    return 'True north • magnetic declination $degrees° $direction';
  }

  @override
  String get directionEast => 'east';

  @override
  String get directionWest => 'west';

  @override
  String get northUp => 'North is up ↑';

  @override
  String get calibrationHint =>
      'Magnetic interference: move away from metal and magnets (such as a phone case), then wave the device in a figure 8 to calibrate the compass.';

  @override
  String get qiblaDirection => 'Qibla direction';

  @override
  String degreesFromNorth(String degrees) {
    return '$degrees° from north';
  }

  @override
  String get distanceToKaaba => 'Distance to the Kaaba';

  @override
  String kilometers(String value) {
    return '$value km';
  }

  @override
  String get setYourLocation => 'Set your location';

  @override
  String get changeMyLocation => 'Change my location';

  @override
  String get calendarHint =>
      'Large number: Hijri • small: Gregorian — use the arrows to change the month';

  @override
  String get eventsTitle => 'Events & announcements';

  @override
  String get eventsSubtitle =>
      'Announcements for Ramadan, the Eids and the Hijri new year in your country';

  @override
  String get syncing => 'Syncing…';

  @override
  String get syncNow => 'Sync announcements now';

  @override
  String errorWith(String error) {
    return 'Error: $error';
  }

  @override
  String get noAnnouncements =>
      'No announcements yet — choose your country in Settings, then sync.';

  @override
  String get syncPickCountry => 'Choose your country first';

  @override
  String syncNewAlerts(String count) {
    return 'New alerts: $count';
  }

  @override
  String get syncNothingNew => 'Synced — nothing new';

  @override
  String syncFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get eventHijriNewYear => 'Islamic New Year';

  @override
  String get eventShaban => 'Start of Sha\'ban';

  @override
  String get eventRamadan => 'Start of Ramadan';

  @override
  String get eventEidFitr => 'Eid al-Fitr';

  @override
  String get eventDhulHijjah => 'Start of Dhu al-Hijjah';

  @override
  String monthStart(String month) {
    return 'Start of $month';
  }

  @override
  String get notifBodyHijriNewYear =>
      'The new Hijri year has begun — Happy New Year.';

  @override
  String get notifBodyShaban =>
      'Sha\'ban has begun — time to prepare for Ramadan.';

  @override
  String get notifBodyRamadan =>
      'The blessed month of Ramadan has begun — Ramadan Kareem.';

  @override
  String get notifBodyEidFitr => 'Shawwal has begun — Eid Mubarak.';

  @override
  String get notifBodyDhulHijjah =>
      'Dhu al-Hijjah has begun — Arafah and Eid al-Adha are near.';

  @override
  String get channelName => 'Islamic events';

  @override
  String get channelDescription =>
      'Announcements for Ramadan, the Eids and the Hijri new year';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionLocation => 'Location';

  @override
  String get change => 'Change';

  @override
  String get sectionPrayerTimes => 'Prayer times';

  @override
  String get calculationMethod => 'Calculation method';

  @override
  String get manualHijriAdjust => 'Manual Hijri adjustment';

  @override
  String get doubleCorrectionWarning =>
      'Your country\'s calendar is already corrected from sighting announcements; this adjustment is added on top and shifts the date twice.';

  @override
  String get reset => 'Reset';

  @override
  String get manualAdjustHint =>
      'Fallback only: keep it at zero while your country is set under “Events”.';

  @override
  String get sectionEvents => 'Events';

  @override
  String get country => 'Country';

  @override
  String get choose => 'Choose';

  @override
  String get sectionAdvanced => 'Advanced';

  @override
  String get horizonTitle => 'Height above the surrounding horizon';

  @override
  String get horizonDescription =>
      'For observers overlooking a lower horizon (a mountain above the sea). Delays Maghrib and advances sunrise — keep it off to match Umm al-Qura.';

  @override
  String get off => 'Off';

  @override
  String get horizonDialogTitle => 'Height above the surrounding horizon (m)';

  @override
  String get horizonDialogHint =>
      'e.g. 300 — not your city\'s altitude above sea level';

  @override
  String get turnOff => 'Turn off';

  @override
  String get save => 'Save';

  @override
  String get sectionInfo => 'About';

  @override
  String get aboutApp => 'About the app';

  @override
  String get language => 'Language';

  @override
  String get languageDevice => 'Device language';

  @override
  String meters(String value) {
    return '$value m';
  }

  @override
  String get methodUmmAlQura => 'Umm al-Qura (Saudi Arabia)';

  @override
  String get methodMuslimWorldLeague => 'Muslim World League';

  @override
  String get methodEgyptian => 'Egyptian General Authority of Survey';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodNorthAmerica => 'North America (ISNA)';

  @override
  String get methodDubai => 'Dubai';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodMoonsighting => 'Moonsighting Committee';

  @override
  String get methodSingapore => 'Singapore';

  @override
  String get methodTurkey => 'Turkey (Diyanet)';

  @override
  String get methodTehran => 'Tehran';

  @override
  String get pickerTitle => 'Set location';

  @override
  String currentLocation(String label) {
    return 'Current: $label';
  }

  @override
  String get useGps => 'Use my current location (GPS)';

  @override
  String get orPickCityIn => 'Or pick a city in';

  @override
  String get noCitiesForCountry =>
      'No built-in cities for this country yet — enter coordinates manually.';

  @override
  String get enterCoordinates => 'Enter coordinates manually';

  @override
  String get openAppSettings => 'Settings';

  @override
  String get turnOn => 'Turn on';

  @override
  String get coordinatesTitle => 'Coordinates';

  @override
  String get latitudeLabel => 'Latitude (north +)';

  @override
  String get longitudeLabel => 'Longitude (east +)';

  @override
  String get latitudeHint => 'e.g. 24.7136';

  @override
  String get longitudeHint => 'e.g. 46.6753';

  @override
  String get latitudeRange => 'Latitude must be between −90 and 90';

  @override
  String get longitudeRange => 'Longitude must be between −180 and 180';

  @override
  String get cancel => 'Cancel';

  @override
  String get gpsServiceDisabled =>
      'Location services are off — turn them on or pick your city.';

  @override
  String get gpsDenied =>
      'Location permission was not granted — you can pick your city manually.';

  @override
  String get gpsDeniedForever =>
      'Location permission is permanently denied — enable it in the app settings or pick your city.';

  @override
  String get gpsUnavailable =>
      'Couldn\'t get your location right now — try again later or pick your city.';

  @override
  String get aboutTitle => 'About the app';

  @override
  String versionBuild(String version, String build) {
    return 'Version $version  •  Build $build';
  }

  @override
  String get aboutDescription =>
      'Ghuroubi Time shows the sunset-based (ghuroubi) clock, the Hijri calendar and prayer times computed precisely for your location, along with the Qibla direction and Islamic events.';

  @override
  String get contactSection => 'Contact';

  @override
  String get website => 'Website';

  @override
  String get contactUs => 'Contact us';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get technicalInfo => 'Technical info';

  @override
  String get identifier => 'Identifier';

  @override
  String get gregorianDateLabel => 'Gregorian date';

  @override
  String get hijriDateLabel => 'Hijri date';

  @override
  String get outOfRange => 'Outside the supported range';

  @override
  String get converterTitle => 'Date converter';

  @override
  String get gregToHijri => 'Gregorian → Hijri';

  @override
  String get hijriToGreg => 'Hijri → Gregorian';

  @override
  String get durationTitle => 'Duration / age';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get setToToday => 'Set “To” to today';

  @override
  String get gregorianCalendar => 'Gregorian';

  @override
  String get hijriCalendar => 'Hijri';

  @override
  String totalDaysWeeks(String days, String weeks) {
    return 'Total: $days days • $weeks weeks';
  }

  @override
  String get unitYears => 'years';

  @override
  String get unitMonths => 'months';

  @override
  String get unitDays => 'days';

  @override
  String get pickHijriDate => 'Pick a Hijri date';

  @override
  String get dayHeader => 'Day';

  @override
  String get monthHeader => 'Month';

  @override
  String get yearHeader => 'Year';

  @override
  String get confirm => 'Confirm';
}
