/// أدوات التنسيق بلغة الواجهة ([AppLanguage]): الأرقام (هندية للعربية، لاتينية
/// للإنجليزية) وصيغ الوقت والتاريخ وأسماء الأشهر والأيام.
library;

import 'app_language.dart';

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

/// الأرقام بشكل لغة الواجهة: هندية للعربية، ولاتينية كما هي للإنجليزية.
String localDigits(String input) =>
    AppLanguage.isArabic ? toArabicDigits(input) : input;

/// يقرأ عدداً عشرياً كتبه المستخدم بأرقام عربية-هندية (٠–٩) أو فارسية (۰–۹) أو
/// لاتينية، وبفاصلة عشرية «٫» أو «,» أو «.». يُعيد null إن لم يكن عدداً.
double? parseLocalizedDouble(String input) {
  final buffer = StringBuffer();
  for (final unit in input.trim().runes) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      buffer.writeCharCode(0x30 + unit - 0x0660); // ٠–٩
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      buffer.writeCharCode(0x30 + unit - 0x06F0); // ۰–۹
    } else if (unit == 0x066B || unit == 0x2C) {
      buffer.write('.'); // «٫» أو «,»
    } else if (unit == 0x2212) {
      buffer.write('-'); // علامة الطرح الرياضية
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return double.tryParse(buffer.toString());
}

/// صيغة 12 ساعة من ساعة 24 ودقيقة: «٣:٠٥ م» بالعربية، «3:05 PM» بالإنجليزية.
String fmt12FromHm(int hour24, int minute) {
  final ar = AppLanguage.isArabic;
  final period = hour24 < 12 ? (ar ? 'ص' : 'AM') : (ar ? 'م' : 'PM');
  var h = hour24 % 12;
  if (h == 0) h = 12;
  return localDigits('$h:${minute.toString().padLeft(2, '0')} $period');
}

/// صيغة 12 ساعة من [DateTime] (بتوقيت الجهاز).
String fmt12(DateTime t) => fmt12FromHm(t.hour, t.minute);

const _gregorianMonths = {
  'ar': [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', //
    'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ],
  'en': [
    '', 'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ],
};

String gregorianMonthName(int month) =>
    _gregorianMonths[AppLanguage.code]![month];

// أسماء الأشهر الهجرية بإملائها الصحيح — مرجع واحد لكل الشاشات بدل
// `HijriCalendar.longMonthName` (حزمة `hijri` تكتب «ربيع الاول» و«جمادى الأول»
// و«جمادى الثاني»)، والعربية مطابقة لأسماء الخادم (`server/lib/events.php`).
const _hijriMonths = {
  'ar': [
    '', 'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', //
    'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ],
  'en': [
    '', 'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Akhir", //
    'Jumada al-Ula', 'Jumada al-Akhirah', 'Rajab', "Sha'ban", 'Ramadan',
    'Shawwal', "Dhu al-Qa'dah", 'Dhu al-Hijjah',
  ],
};

String hijriMonthName(int month) => _hijriMonths[AppLanguage.code]![month];

const _weekdays = {
  'ar': ['', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
  'en': ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
};

// رؤوس أعمدة التقويم (أسماء كاملة بلا «ال» للعربية — تتّسع لها الأعمدة السبعة).
const _weekdaysShort = {
  'ar': ['', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'],
  'en': ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
};

/// اسم اليوم ([DateTime.weekday]: الاثنين=1 .. الأحد=7).
String weekdayName(int weekday) => _weekdays[AppLanguage.code]![weekday];

/// اسم اليوم المختصر لرأس عمود التقويم.
String weekdayShort(int weekday) => _weekdaysShort[AppLanguage.code]![weekday];

/// ليلة اليوم [weekday] الإسلامية (تبدأ بمغرب اليوم السابق): «ليلة الجمعة» /
/// «Friday eve».
String nightOf(int weekday) => AppLanguage.isArabic
    ? 'ليلة ${weekdayName(weekday)}'
    : '${weekdayName(weekday)} eve';

/// لاحقة التاريخ الهجري: «هـ» / «AH».
String get hijriEra => AppLanguage.isArabic ? 'هـ' : 'AH';

/// تاريخ هجري كامل: «١٨ ربيع الآخر ١٤٤٨ هـ» / «18 Rabi' al-Akhir 1448 AH».
String formatHijriDate(int day, int month, int year) =>
    localDigits('$day ${hijriMonthName(month)} $year $hijriEra');

/// تاريخ ميلادي: «٢٩ سبتمبر ٢٠٢٦ م» / «29 September 2026». [withEra] يضيف «م»
/// في العربية (الإنجليزية لا تحتاج لاحقة).
String formatGregorianDate(DateTime d, {bool withEra = true}) {
  final era = withEra && AppLanguage.isArabic ? ' م' : '';
  return localDigits('${d.day} ${gregorianMonthName(d.month)} ${d.year}$era');
}

/// تنسيق مدّة للعدّاد التنازلي: «٣س ٥د ٢ث» / «3h 5m 2s».
String formatDuration(Duration d) {
  final ar = AppLanguage.isArabic;
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final parts = <String>[];
  if (h > 0) parts.add(ar ? '$hس' : '${h}h');
  parts.add(ar ? '$mد' : '${m}m');
  parts.add(ar ? '$sث' : '${s}s');
  return localDigits(parts.join(' '));
}
