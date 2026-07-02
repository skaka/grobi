/// قائمة الدول (تطابق بذور الخادم) — الرمز يُستخدم كموضوع FCM واشتراك.
class Country {
  final String code;
  final String nameAr;
  const Country(this.code, this.nameAr);
}

const List<Country> kCountries = [
  Country('sa', 'السعودية'),
  Country('ae', 'الإمارات'),
  Country('kw', 'الكويت'),
  Country('qa', 'قطر'),
  Country('bh', 'البحرين'),
  Country('om', 'عُمان'),
  Country('jo', 'الأردن'),
  Country('eg', 'مصر'),
  Country('sy', 'سوريا'),
  Country('ps', 'فلسطين'),
  Country('iq', 'العراق'),
  Country('ye', 'اليمن'),
  Country('lb', 'لبنان'),
];

String? countryNameAr(String? code) {
  if (code == null) return null;
  for (final c in kCountries) {
    if (c.code == code) return c.nameAr;
  }
  return null;
}
