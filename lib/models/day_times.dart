/// أنواع الأوقات اليومية (الصلوات الخمس + الشروق).
enum PrayerKind { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerKindName on PrayerKind {
  /// هل هو صلاة مفروضة (لأغراض العدّاد التنازلي)؟ الشروق ليس صلاة.
  bool get isSalah => this != PrayerKind.sunrise;
}

/// مواقيت يوم واحد بعد تصحيح الارتفاع (كلها بتوقيت الجهاز المحلي).
/// [maghrib] = الغروب المصحّح، وهو ما يغذّي الساعة الغروبية.
class DayTimes {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DayTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  DateTime timeOf(PrayerKind kind) {
    switch (kind) {
      case PrayerKind.fajr:
        return fajr;
      case PrayerKind.sunrise:
        return sunrise;
      case PrayerKind.dhuhr:
        return dhuhr;
      case PrayerKind.asr:
        return asr;
      case PrayerKind.maghrib:
        return maghrib;
      case PrayerKind.isha:
        return isha;
    }
  }

  /// الأوقات مرتّبة زمنياً.
  List<MapEntry<PrayerKind, DateTime>> get ordered => [
        MapEntry(PrayerKind.fajr, fajr),
        MapEntry(PrayerKind.sunrise, sunrise),
        MapEntry(PrayerKind.dhuhr, dhuhr),
        MapEntry(PrayerKind.asr, asr),
        MapEntry(PrayerKind.maghrib, maghrib),
        MapEntry(PrayerKind.isha, isha),
      ];
}
