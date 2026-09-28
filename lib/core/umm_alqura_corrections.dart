import 'dart:math' show max;

import 'package:hijri/hijri_calendar.dart';

import '../models/islamic_event.dart';
import 'date_utils.dart';

/// تصحيح تقويم أم القرى (المضمَّن في حزمة `hijri`) من إعلانات الرؤية المؤكّدة.
///
/// الحزمة تحمل جدول أم القرى الرسمي، وتوفّر آلية «تعديلات» (`adjustments`) تُلغي
/// إدخالاً محدّداً من الجدول: المفتاح = ترتيب بداية الشهر الهجري المطلق، والقيمة =
/// «mcjdn» (Modified Chronological Julian Day Number) ليوم بداية الشهر.
///
/// تحريك حدٍّ واحد يُغيّر طول الشهر الذي قبله، فيولّد أشهراً من 28 أو 31 يوماً.
/// لذا نثبّت الأشهر المُعلَنة ثم ننشر أقلّ تغيير ممكن للأمام وللخلف حتى يعود كل
/// شهر 29 أو 30 يوماً (انظر [buildAnchoring]).

/// مدى جدول أم القرى في الحزمة: 1356..1500 هـ — نتجنّب الحواف احتياطاً.
const int _minHYear = 1357;
const int _maxHYear = 1499;

/// أقصى فرق مقبول (بالأيام) بين إعلان وبداية شهره في جدول أم القرى. الدول تختلف
/// عن الجدول بيوم، ونادراً بيومين؛ ما زاد فخطأ إدخال لا يُطبَّق.
const int maxAnchorDriftDays = 2;

/// «mcjdn» ليوم ميلادي — بنفس صيغة `HijriCalendar.gregorianToHijri` (CJDN − 2400000).
int gregorianToMcjdn(DateTime g) {
  int y = g.year;
  int m = g.month;
  final int day = g.day;
  // ألحِق يناير/فبراير بالسنة السابقة (مارس = أول الشهور) لتبسيط الكبائس.
  if (m < 3) {
    y -= 1;
    m += 12;
  }
  final int a = (y / 100).floor();
  final int jgc = a - (a / 4.0).floor() - 2;
  final int cjdn = (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day -
      jgc -
      1524;
  return cjdn - 2400000;
}

/// مفتاح `adjustments` لبداية الشهر (hYear, hMonth) — يطابق فهرسة الحزمة.
int adjustmentKey(int hYear, int hMonth) => (hYear - 1) * 12 + hMonth - 1;

/// حدود المفاتيح التي تُعدَّل: من أول محرّم [_minHYear] حتى أول محرّم بعد
/// [_maxHYear] (حدّ نهاية ذي الحجة الأخير).
final int _minKey = adjustmentKey(_minHYear, 1);
final int _maxKey = adjustmentKey(_maxHYear + 1, 1);

/// بداية الشهر ذي المفتاح [key] في جدول أم القرى **غير المُصحَّح** (mcjdn).
int tableMonthStart(int key) {
  final h = HijriCalendar();
  return gregorianToMcjdn(h.hijriToGregorian(key ~/ 12 + 1, key % 12 + 1, 1));
}

/// حصيلة تثبيت الأشهر: خريطة التعديلات للحزمة + ملاحظات (إعلان مرفوض، أو تعارض
/// بين تثبيتين لا يسمح بأشهر 29/30) لسجلّ التشخيص.
class HijriAnchoring {
  final Map<int, int> adjustments;
  final List<String> issues;

  const HijriAnchoring(this.adjustments, this.issues);
}

/// يثبّت بداية كل شهر مُعلَن في تاريخه، ثم يعدّل أقلّ عدد من الأشهر المجاورة كي
/// يبقى **كل** شهر 29 أو 30 يوماً:
///
/// 1. إعلان يبعد أكثر من [maxAnchorDriftDays] عن الجدول يُرفَض (لا يُطبَّق).
/// 2. من كل شهر مثبَّت نسير للأمام: ما دام طول الشهر ليس 29/30 نقرّب بداية التالي
///    إلى أقرب قيمة صالحة (30 إن طال، 29 إن قصر)، ثم ننتقل إليه.
/// 3. ونسير للخلف بالمثل على الشهر السابق.
/// 4. لا يُحرَّك شهر مثبَّت أبداً؛ إن بقي بعد السير كله شهرٌ غير صالح بين
///    تثبيتين فهذا تعارض بين إعلانين يُسجَّل وتبقى الإعلانات كما هي.
///
/// عند تكرار نفس الشهر يفوز الأخير في القائمة.
HijriAnchoring buildAnchoring(List<EventAnnouncement> announcements) {
  final issues = <String>{};
  final anchors = <int, int>{};

  for (final a in announcements) {
    if (a.hijriYear < _minHYear ||
        a.hijriYear > _maxHYear ||
        a.hijriMonth < 1 ||
        a.hijriMonth > 12) {
      continue;
    }
    final key = adjustmentKey(a.hijriYear, a.hijriMonth);
    final announced = gregorianToMcjdn(a.gregorianDate);
    final drift = announced - tableMonthStart(key);
    if (drift.abs() > maxAnchorDriftDays) {
      issues.add('رُفض تثبيت ${a.hijriMonth}/${a.hijriYear}: '
          'يبعد $drift يوماً عن جدول أم القرى');
      continue;
    }
    anchors[key] = announced;
  }

  final starts = Map<int, int>.of(anchors);
  int startOf(int key) => starts[key] ?? tableMonthStart(key);
  bool valid(int length) => length == 29 || length == 30;
  int nearestValid(int length) => length > 30 ? 30 : 29;

  // تصاعدياً: السير للأمام من تثبيت قد يبلغ التالي وطولٌ ما زال غير صالح، فيُصلحه
  // السير للخلف من ذلك التالي (يأتي بعده). لذا لا يُحكم بالتعارض أثناء السير.
  final ordered = anchors.keys.toList()..sort();
  for (final anchor in ordered) {
    // للأمام: طول الشهر m = بداية m+1 − بداية m.
    for (var m = anchor; m + 1 <= _maxKey && !anchors.containsKey(m + 1); m++) {
      final length = startOf(m + 1) - startOf(m);
      if (valid(length)) break;
      starts[m + 1] = startOf(m) + nearestValid(length);
    }
    // للخلف: طول الشهر m−1 = بداية m − بداية m−1.
    for (var m = anchor; m - 1 >= _minKey && !anchors.containsKey(m - 1); m--) {
      final length = startOf(m) - startOf(m - 1);
      if (valid(length)) break;
      starts[m - 1] = startOf(m) - nearestValid(length);
    }
  }

  // تعارض حقيقي = شهر مسّه التصحيح وبقي طوله غير صالح بين التثبيتات: السير للخلف
  // يجعل كل شهر بينها 29 (أو 30) كلها، فإن لم يكفِ فلا توزيع 29/30 يصل التثبيتين.
  // (شهر لم يُمَسّ حدّاه يبقى كما في الجدول — وفيه شذوذ تاريخي وحيد: شعبان 1364.)
  if (ordered.isNotEmpty) {
    for (var m = max(ordered.first - 1, _minKey); m <= ordered.last; m++) {
      final touched = starts.containsKey(m) || starts.containsKey(m + 1);
      final length = startOf(m + 1) - startOf(m);
      if (touched && !valid(length)) {
        issues.add('تعارض تثبيتين: الشهر ${m % 12 + 1}/${m ~/ 12 + 1} '
            'طوله $length يوماً');
      }
    }
  }

  return HijriAnchoring(starts, issues.toList());
}

/// خريطة تصحيحات جدول أم القرى من إعلانات الرؤية (انظر [buildAnchoring]).
Map<int, int> adjustmentsFromAnnouncements(
        List<EventAnnouncement> announcements) =>
    buildAnchoring(announcements).adjustments;

/// تاريخ هجري مُصحَّح من تاريخ ميلادي، مع إزاحة يدوية عامة احتياطية [manualAdjust].
HijriCalendar correctedHijri(DateTime gregorian, Map<int, int> adjustments,
    {int manualAdjust = 0}) {
  final h = HijriCalendar()..adjustments = adjustments;
  final d = addDays(gregorian, manualAdjust);
  h.gregorianToHijri(d.year, d.month, d.day);
  return h;
}

/// أول يوم ميلادي لشهر هجري (بعد التصحيح).
DateTime correctedMonthStart(int hYear, int hMonth, Map<int, int> adjustments) {
  final h = HijriCalendar()..adjustments = adjustments;
  return dateOnly(h.hijriToGregorian(hYear, hMonth, 1));
}

/// عدد أيام شهر هجري (بعد التصحيح): 29 أو 30.
int correctedMonthLength(int hYear, int hMonth, Map<int, int> adjustments) {
  final h = HijriCalendar()..adjustments = adjustments;
  return h.getDaysInMonth(hYear, hMonth);
}

/// شهر هجري كما تعرضه شبكة التقويم: تاريخ ميلادي لكل يوم هجري.
class HijriMonthGrid {
  final int hYear;
  final int hMonth;

  /// `days[i]` = التاريخ الميلادي (بلا وقت) لليوم الهجري `i + 1`.
  final List<DateTime> days;

  const HijriMonthGrid(this.hYear, this.hMonth, this.days);

  DateTime get start => days.first;
  DateTime get end => days.last;

  /// خانات فارغة قبل اليوم الأول في شبكة تبدأ بالسبت.
  int get leadingFromSaturday => (start.weekday - DateTime.saturday + 7) % 7;
}

/// يبني شبكة الشهر ([hYear], [hMonth]) بعد التصحيح والإزاحة اليدوية. كل خلية تُحسب
/// بأيام تقويمية ([addDays]) لا بمضاعفات 24 ساعة، فلا يُكرَّر يوم ولا يُقفَز عنه في
/// شهر يعبر انتقال التوقيت الصيفي.
HijriMonthGrid hijriMonthGrid(
    int hYear, int hMonth, Map<int, int> adjustments,
    {int manualAdjust = 0}) {
  final start =
      addDays(correctedMonthStart(hYear, hMonth, adjustments), -manualAdjust);
  final length = correctedMonthLength(hYear, hMonth, adjustments);
  return HijriMonthGrid(
      hYear, hMonth, [for (var i = 0; i < length; i++) addDays(start, i)]);
}
