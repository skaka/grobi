import 'package:hijri/hijri_calendar.dart';

import '../models/islamic_event.dart';

/// منطق معايرة التقويم الهجري من إعلانات الرؤية (نقيّ، بلا حالة، قابل للاختبار).
///
/// التطبيق يحسب الهجري بإضافة «التعديل» إلى التاريخ الميلادي قبل التحويل
/// (`HijriCalendar.fromDate(G + adjust)`). لذا إذا كانت الرؤية الرسمية تجعل بداية
/// الشهر في تاريخ ميلادي [official]، والحزمة تتوقّعها في [pkg]، فالإزاحة المطلوبة
/// = `pkg − official` (بالأيام).

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// اقتراح معايرة ناتج عن إعلان رؤية.
class CalibrationSuggestion {
  final EventAnnouncement announcement;
  final int currentAdjust;
  final int suggestedAdjust;

  const CalibrationSuggestion({
    required this.announcement,
    required this.currentAdjust,
    required this.suggestedAdjust,
  });

  /// مفتاح المعالجة: يربط الإعلان بالإزاحة المقترحة، كي يُعاد الاقتراح لو صحّح
  /// المشرف التاريخ لاحقاً (تتغيّر الإزاحة فيتغيّر المفتاح).
  String get handledKey => '${announcement.key}:$suggestedAdjust';
}

/// الإزاحة (±يوم) اللازمة كي يطابق تقويم التطبيق بداية الشهر المُعلَنة في [a].
/// تُعيد null إذا كانت بيانات الإعلان غير صالحة (سنة هجرية ≤ 0).
int? suggestedHijriAdjust(EventAnnouncement a) {
  if (a.hijriYear <= 0) return null;
  final pkgFirstDay =
      HijriCalendar().hijriToGregorian(a.hijriYear, a.type.hijriMonth, 1);
  return _dateOnly(pkgFirstDay)
      .difference(_dateOnly(a.gregorianDate))
      .inDays;
}

/// يختار أقرب إعلانٍ ذي صلة يقترح إزاحة تختلف عن الحالية ولم تُعالَج بعد.
///
/// [isRelevant] يُمرَّر من المزوّد (`relevantForNotification`) ليكون مصدر النافذة
/// الزمنية واحداً. يُرجِع null إن لم يوجد اقتراح معلّق.
CalibrationSuggestion? pickPendingSuggestion({
  required List<EventAnnouncement> stored,
  required int currentAdjust,
  required Set<String> handledKeys,
  required DateTime now,
  required bool Function(DateTime eventDate, DateTime now) isRelevant,
}) {
  CalibrationSuggestion? best;
  int? bestDistance;
  for (final a in stored) {
    if (!isRelevant(a.gregorianDate, now)) continue;
    final suggested = suggestedHijriAdjust(a);
    if (suggested == null || suggested == currentAdjust) continue;
    final candidate = CalibrationSuggestion(
      announcement: a,
      currentAdjust: currentAdjust,
      suggestedAdjust: suggested,
    );
    if (handledKeys.contains(candidate.handledKey)) continue;
    final distance =
        _dateOnly(a.gregorianDate).difference(_dateOnly(now)).inDays.abs();
    if (bestDistance == null || distance < bestDistance) {
      best = candidate;
      bestDistance = distance;
    }
  }
  return best;
}
