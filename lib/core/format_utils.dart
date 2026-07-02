/// أدوات تنسيق عربية (أرقام هندية + صيغ الوقت والتاريخ).
library;

const _arabicDigits = {
  '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
  '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩',
};

/// يحوّل الأرقام اللاتينية إلى عربية-هندية (بحث في خريطة بدل `indexOf` لكل محرف).
String toArabicDigits(String input) {
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    buffer.write(_arabicDigits[ch] ?? ch);
  }
  return buffer.toString();
}

/// صيغة 12 ساعة بالعربية مع ص/م وأرقام هندية، من ساعة 24 ودقيقة.
String fmt12FromHm(int hour24, int minute) {
  final period = hour24 < 12 ? 'ص' : 'م';
  var h = hour24 % 12;
  if (h == 0) h = 12;
  return toArabicDigits('$h:${minute.toString().padLeft(2, '0')} $period');
}

/// صيغة 12 ساعة من [DateTime] (بتوقيت الجهاز).
String fmt12(DateTime t) => fmt12FromHm(t.hour, t.minute);

const _gregorianMonthsAr = [
  '',
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String gregorianMonthAr(int month) => _gregorianMonthsAr[month];

// أسماء الأشهر الهجرية — منسوخة حرفياً من حزمة `hijri` (arMonthNames) لتتطابق
// مع ترويسة التقويم التي تستخدم `HijriCalendar.longMonthName`.
const _hijriMonthsAr = [
  '',
  'محرم',
  'صفر',
  'ربيع الاول',
  'ربيع الثاني',
  'جمادى الأول',
  'جمادى الثاني',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

String hijriMonthAr(int month) => _hijriMonthsAr[month];

const _weekdaysAr = [
  '',
  'الإثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// اسم اليوم بالعربية ([DateTime.weekday]: الإثنين=1 .. الأحد=7).
String weekdayAr(int weekday) => _weekdaysAr[weekday];

/// تنسيق مدّة كـ "Hس Mد Sث" بأرقام هندية (للعدّاد التنازلي).
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final parts = <String>[];
  if (h > 0) parts.add('$hس');
  parts.add('$mد');
  parts.add('$sث');
  return toArabicDigits(parts.join(' '));
}
