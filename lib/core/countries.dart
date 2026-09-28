import 'app_language.dart';

/// دولة الإعلانات — الرمز يُستخدم كموضوع FCM واشتراك.
class Country {
  final String code;
  final String nameAr;
  final String? nameEn;
  const Country(this.code, this.nameAr, [this.nameEn]);

  /// الاسم بلغة الواجهة (العربي احتياطاً إن غاب الإنجليزي).
  String get name => AppLanguage.isArabic ? nameAr : (nameEn ?? nameAr);

  /// رمز صالح اسماً لموضوع FCM (حروف صغيرة وأرقام وشرطة، مثل `id-muh` مستقبلاً).
  static final RegExp _codePattern = RegExp(r'^[a-z][a-z0-9-]{1,9}$');

  /// من سطر `/api/v1/countries.php`: {code, name_ar, name_en}. null إن كان ناقصاً.
  static Country? fromServer(Map<String, dynamic> json) {
    final code = json['code'];
    final name = json['name_ar'];
    final nameEn = json['name_en'];
    if (code is! String || name is! String) return null;
    if (!_codePattern.hasMatch(code) || name.trim().isEmpty) return null;
    return Country(code, name.trim(),
        nameEn is String && nameEn.trim().isNotEmpty ? nameEn.trim() : null);
  }

  Map<String, dynamic> toJson() =>
      {'code': code, 'name_ar': nameAr, 'name_en': nameEn};
}

/// القائمة المضمَّنة (تطابق بذور الخادم) — احتياط عند تعذّر الاتصال أول مرة.
const List<Country> kCountries = [
  Country('sa', 'السعودية', 'Saudi Arabia'),
  Country('ae', 'الإمارات', 'United Arab Emirates'),
  Country('kw', 'الكويت', 'Kuwait'),
  Country('qa', 'قطر', 'Qatar'),
  Country('bh', 'البحرين', 'Bahrain'),
  Country('om', 'عُمان', 'Oman'),
  Country('jo', 'الأردن', 'Jordan'),
  Country('eg', 'مصر', 'Egypt'),
  Country('sy', 'سوريا', 'Syria'),
  Country('ps', 'فلسطين', 'Palestine'),
  Country('iq', 'العراق', 'Iraq'),
  Country('ye', 'اليمن', 'Yemen'),
  Country('lb', 'لبنان', 'Lebanon'),
];

/// اسم الدولة بلغة الواجهة من قائمة [countries]، ثم من القائمة المضمَّنة.
String? countryName(String? code, [List<Country> countries = kCountries]) {
  if (code == null) return null;
  for (final c in [...countries, ...kCountries]) {
    if (c.code == code) return c.name;
  }
  return null;
}
