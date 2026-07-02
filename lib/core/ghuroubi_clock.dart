/// الساعة الغروبية: ساعات متساوية (60 دقيقة) تُعدّ من الغروب.
/// لحظة المغرب = 12:00، ثم يتصاعد العدّ حتى مغرب اليوم التالي.
class GhuroubiClock {
  /// المنقضي منذ آخر غروب.
  final Duration sinceSunset;

  /// المتبقّي حتى الغروب القادم (لحظة تبديل اليوم الغروبي).
  final Duration untilNextSunset;

  /// هل نحن في النهار (بين الشروق والغروب)؟
  final bool isDaytime;

  const GhuroubiClock({
    required this.sinceSunset,
    required this.untilNextSunset,
    required this.isDaytime,
  });

  /// يحسب الساعة الغروبية في لحظة [now] اعتماداً على أوقات الغروب المصحّحة
  /// (الأمس/اليوم/الغد) وشروق اليوم.
  static GhuroubiClock at({
    required DateTime now,
    required DateTime yesterdayMaghrib,
    required DateTime todaySunrise,
    required DateTime todayMaghrib,
    required DateTime tomorrowMaghrib,
  }) {
    final beforeSunset = now.isBefore(todayMaghrib);
    final lastSunset = beforeSunset ? yesterdayMaghrib : todayMaghrib;
    final nextSunset = beforeSunset ? todayMaghrib : tomorrowMaghrib;
    return GhuroubiClock(
      sinceSunset: now.difference(lastSunset),
      untilNextSunset: nextSunset.difference(now),
      isDaytime: now.isAfter(todaySunrise) && now.isBefore(todayMaghrib),
    );
  }

  /// إجمالي الثواني الغروبية منذ منتصف ليل الوجه (المغرب = 12:00:00).
  int get _totalSeconds => 12 * 3600 + sinceSunset.inSeconds;

  /// الساعة على وجه 12 (1..12، المغرب = 12).
  int get hour12 {
    final h = (_totalSeconds ~/ 3600) % 12;
    return h == 0 ? 12 : h;
  }

  int get minute => (_totalSeconds ~/ 60) % 60;
  int get second => _totalSeconds % 60;

  /// نسبة انقضاء اليوم الغروبي (0..1) — لرسم القوس.
  double get dayProgress {
    final total = sinceSunset.inSeconds + untilNextSunset.inSeconds;
    if (total <= 0) return 0;
    return sinceSunset.inSeconds / total;
  }

  /// صياغة `H:MM` غروبية.
  String format() => '$hour12:${minute.toString().padLeft(2, '0')}';
}
