import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/app_language.dart';
import 'package:timer_grobi/core/countries.dart';
import 'package:timer_grobi/services/countries_api.dart';

void main() {
  group('قائمة الدول من الخادم', () {
    test('تُستخرج الدول الصالحة ويُسقط المكرَّر والناقص', () {
      final list = parseCountries({
        'api_version': '1.0',
        'count': 5,
        'countries': [
          {'code': 'sa', 'name_ar': 'السعودية', 'name_en': 'Saudi Arabia'},
          {'code': 'ma', 'name_ar': ' المغرب ', 'name_en': 'Morocco'},
          {'code': 'id-muh', 'name_ar': 'إندونيسيا (المحمدية)'},
          {'code': 'sa', 'name_ar': 'مكرّر'},
          {'code': 'XX', 'name_ar': 'رمز غير صالح'},
          {'code': 'eg'},
          'ليس كائناً',
        ],
      });
      expect(list.map((c) => c.code), ['sa', 'ma', 'id-muh']);
      expect(list[1].nameAr, 'المغرب');
    });

    test('استجابة غير متوقعة ⇒ قائمة فارغة (فيُبقى الاحتياط)', () {
      expect(parseCountries(null), isEmpty);
      expect(parseCountries({'error': 'x'}), isEmpty);
      expect(parseCountries([]), isEmpty);
    });

    test('ذهاب/عودة الحفظ المحلي', () {
      final json = {'countries': [for (final c in kCountries) c.toJson()]};
      expect(parseCountries(json).map((c) => c.code),
          kCountries.map((c) => c.code));
    });

    test('اسم الدولة بلغة الواجهة من القائمة الممرَّرة أو المضمَّنة', () {
      addTearDown(() => AppLanguage.code = 'ar');
      AppLanguage.code = 'ar';
      expect(countryName('eg'), 'مصر');
      expect(countryName('ma', const [Country('ma', 'المغرب', 'Morocco')]),
          'المغرب');
      expect(countryName('ma'), isNull);
      expect(countryName(null), isNull);
      AppLanguage.code = 'en';
      expect(countryName('eg'), 'Egypt');
      expect(countryName('ma', const [Country('ma', 'المغرب', 'Morocco')]),
          'Morocco');
      expect(countryName('xx', const [Country('xx', 'اسم فقط')]), 'اسم فقط',
          reason: 'بلا اسم إنجليزي ⇒ العربي');
    });

    test('name_en من الخادم يُقرأ ويُحفظ', () {
      final c = Country.fromServer(
          {'code': 'ae', 'name_ar': 'الإمارات', 'name_en': 'United Arab Emirates'});
      expect(c?.nameEn, 'United Arab Emirates');
      expect(parseCountries({'countries': [c!.toJson()]}).single.nameEn,
          'United Arab Emirates');
    });
  });
}
