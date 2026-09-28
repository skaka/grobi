import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/app_language.dart';
import 'package:timer_grobi/core/format_utils.dart';

void main() {
  tearDown(() => AppLanguage.code = 'ar');

  test('أسماء الأشهر الهجرية بالإملاء الصحيح (مطابقة للخادم)', () {
    AppLanguage.code = 'ar';
    expect([for (var m = 1; m <= 12; m++) hijriMonthName(m)], [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ]);
  });

  test('الاثنين بهمزة وصل، و«ليلة الجمعة»', () {
    AppLanguage.code = 'ar';
    expect(weekdayName(DateTime.monday), 'الاثنين');
    expect(weekdayName(DateTime.friday), 'الجمعة');
    expect(nightOf(DateTime.friday), 'ليلة الجمعة');
  });

  test('العربية: أرقام هندية وص/م ولاحقتا التاريخ', () {
    AppLanguage.code = 'ar';
    expect(fmt12FromHm(15, 5), '٣:٠٥ م');
    expect(fmt12FromHm(0, 30), '١٢:٣٠ ص');
    expect(formatHijriDate(18, 4, 1448), '١٨ ربيع الآخر ١٤٤٨ هـ');
    expect(formatGregorianDate(DateTime(2026, 9, 29)), '٢٩ سبتمبر ٢٠٢٦ م');
    expect(formatDuration(const Duration(hours: 3, minutes: 5, seconds: 2)),
        '٣س ٥د ٢ث');
  });

  test('الإنجليزية: أرقام لاتينية وAM/PM وأسماء إنجليزية', () {
    AppLanguage.code = 'en';
    expect(fmt12FromHm(15, 5), '3:05 PM');
    expect(fmt12FromHm(0, 30), '12:30 AM');
    expect(formatHijriDate(18, 4, 1448), "18 Rabi' al-Akhir 1448 AH");
    expect(formatGregorianDate(DateTime(2026, 9, 29)), '29 September 2026');
    expect(formatDuration(const Duration(hours: 3, minutes: 5, seconds: 2)),
        '3h 5m 2s');
    expect(weekdayShort(DateTime.saturday), 'Sat');
    expect(nightOf(DateTime.friday), 'Friday eve');
    expect(localDigits('1448'), '1448');
  });

  test('اختيار لغة الواجهة: المستخدم ثم الجهاز، والعربية لغير الإنجليزية', () {
    expect(AppLanguage.resolve('en', 'ar'), 'en');
    expect(AppLanguage.resolve('ar', 'en'), 'ar');
    expect(AppLanguage.resolve(null, 'en'), 'en');
    expect(AppLanguage.resolve(null, 'ar'), 'ar');
    expect(AppLanguage.resolve(null, 'fr'), 'ar');
    expect(AppLanguage.resolve(null, null), 'ar');
  });
}
