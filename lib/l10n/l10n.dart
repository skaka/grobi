import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';

import '../core/app_language.dart';
import '../core/format_utils.dart';
import '../models/day_times.dart';
import '../models/islamic_event.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// نصوص الواجهة بلغة هذه الشجرة.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// نصوص الواجهة بلغتها الحالية لِما لا يملك `BuildContext`: المزوّدات، ونصوص
/// التنبيهات المحلية، ورسائل GPS.
AppLocalizations get tr => lookupAppLocalizations(Locale(AppLanguage.code));

String prayerName(PrayerKind kind) {
  final t = tr;
  switch (kind) {
    case PrayerKind.fajr:
      return t.prayerFajr;
    case PrayerKind.sunrise:
      return t.prayerSunrise;
    case PrayerKind.dhuhr:
      return t.prayerDhuhr;
    case PrayerKind.asr:
      return t.prayerAsr;
    case PrayerKind.maghrib:
      return t.prayerMaghrib;
    case PrayerKind.isha:
      return t.prayerIsha;
  }
}

String eventName(IslamicEventType type) {
  final t = tr;
  switch (type) {
    case IslamicEventType.hijriNewYear:
      return t.eventHijriNewYear;
    case IslamicEventType.shaban:
      return t.eventShaban;
    case IslamicEventType.ramadan:
      return t.eventRamadan;
    case IslamicEventType.eidFitr:
      return t.eventEidFitr;
    case IslamicEventType.dhulHijjah:
      return t.eventDhulHijjah;
  }
}

/// نصّ التنبيه المحلي لمناسبة (المزامنة/المقدّمة).
String eventNotificationBody(IslamicEventType type) {
  final t = tr;
  switch (type) {
    case IslamicEventType.hijriNewYear:
      return t.notifBodyHijriNewYear;
    case IslamicEventType.shaban:
      return t.notifBodyShaban;
    case IslamicEventType.ramadan:
      return t.notifBodyRamadan;
    case IslamicEventType.eidFitr:
      return t.notifBodyEidFitr;
    case IslamicEventType.dhulHijjah:
      return t.notifBodyDhulHijjah;
  }
}

/// عنوان إعلان للعرض: اسم المناسبة، أو «بداية <الشهر>» للتثبيت الصامت.
String announcementTitle(EventAnnouncement a) {
  final type = a.type;
  return type != null
      ? eventName(type)
      : tr.monthStart(hijriMonthName(a.hijriMonth));
}

String calculationMethodName(CalculationMethod method) {
  final t = tr;
  switch (method) {
    case CalculationMethod.umm_al_qura:
      return t.methodUmmAlQura;
    case CalculationMethod.muslim_world_league:
      return t.methodMuslimWorldLeague;
    case CalculationMethod.egyptian:
      return t.methodEgyptian;
    case CalculationMethod.karachi:
      return t.methodKarachi;
    case CalculationMethod.north_america:
      return t.methodNorthAmerica;
    case CalculationMethod.dubai:
      return t.methodDubai;
    case CalculationMethod.qatar:
      return t.methodQatar;
    case CalculationMethod.kuwait:
      return t.methodKuwait;
    case CalculationMethod.moon_sighting_committee:
      return t.methodMoonsighting;
    case CalculationMethod.singapore:
      return t.methodSingapore;
    case CalculationMethod.turkey:
      return t.methodTurkey;
    case CalculationMethod.tehran:
      return t.methodTehran;
    default:
      return method.name;
  }
}
