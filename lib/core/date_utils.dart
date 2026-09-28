/// حساب الأيام التقويمية الآمن من التوقيت الصيفي.
///
/// إضافة `Duration(days: 1)` تضيف **24 ساعة** بالضبط، فيوم انتقال الساعة
/// (23 أو 25 ساعة) يُنتج 23:00 أو 01:00 من اليوم المجاور، فتنكسر كل مقارنة أو
/// مفتاح مبني على التاريخ. هنا نحسب بحقول (سنة، شهر، يوم) ونترك لـ[DateTime]
/// تطبيع الفائض (32 يناير ⇐ 1 فبراير)، فلا تتأثّر النتيجة بالمنطقة الزمنية.
library;

/// التاريخ بلا وقت (منتصف ليل محلي). عند انعدام منتصف الليل في يوم تقديم
/// الساعة (بيروت، القاهرة) يُعيد Dart الساعة 01:00 من **نفس** اليوم — والحقول
/// (سنة/شهر/يوم) تبقى صحيحة، وهي كل ما نعتمد عليه.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// يضيف [days] يوماً **تقويمياً** (قد يكون سالباً) لتاريخ، ويُعيد تاريخاً بلا وقت.
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// عدد الأيام التقويمية من [from] إلى [to] (موجب إن كان [to] لاحقاً). يُحسب على
/// UTC كي لا يُنقص يوم تأخير الساعة (23 ساعة) الفرق يوماً عند `inDays`.
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// هل اللحظتان في نفس اليوم التقويمي؟
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
