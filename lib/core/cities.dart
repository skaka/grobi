import 'app_language.dart';

/// مدن رئيسية مضمَّنة (بلا إنترنت) لاختيار الموقع يدوياً حين لا يتوفّر GPS.
///
/// الإحداثيات لوسط المدينة بدقّة ~كيلومتر؛ كل 0.01° طولاً ≈ 2.4 ثانية في المواقيت.
class City {
  final String countryCode;
  final String slug; // معرّف ثابت (لا يتغيّر بتغيّر لغة الواجهة)
  final String nameAr;
  final String nameEn;
  final double latitude;
  final double longitude;

  const City(this.countryCode, this.slug, this.nameAr, this.nameEn,
      this.latitude, this.longitude);

  /// معرّف يُحفظ مع الموقع اليدوي: `sa/riyadh`.
  String get id => '$countryCode/$slug';

  /// الاسم بلغة الواجهة.
  String get name => AppLanguage.isArabic ? nameAr : nameEn;
}

const List<City> kCities = [
  City('sa', 'riyadh', 'الرياض', 'Riyadh', 24.7136, 46.6753),
  City('sa', 'jeddah', 'جدة', 'Jeddah', 21.4858, 39.1925),
  City('sa', 'mecca', 'مكة المكرمة', 'Mecca', 21.4225, 39.8262),
  City('sa', 'medina', 'المدينة المنورة', 'Medina', 24.4672, 39.6111),
  City('sa', 'dammam', 'الدمام', 'Dammam', 26.4207, 50.0888),
  City('sa', 'taif', 'الطائف', 'Taif', 21.2703, 40.4158),
  City('sa', 'buraidah', 'بريدة', 'Buraidah', 26.3260, 43.9750),
  City('sa', 'tabuk', 'تبوك', 'Tabuk', 28.3835, 36.5662),
  City('sa', 'hail', 'حائل', 'Hail', 27.5114, 41.7208),
  City('sa', 'abha', 'أبها', 'Abha', 18.2164, 42.5053),
  City('sa', 'jazan', 'جازان', 'Jazan', 16.8892, 42.5511),
  City('sa', 'najran', 'نجران', 'Najran', 17.4924, 44.1277),
  City('ae', 'abu-dhabi', 'أبوظبي', 'Abu Dhabi', 24.4539, 54.3773),
  City('ae', 'dubai', 'دبي', 'Dubai', 25.2048, 55.2708),
  City('ae', 'sharjah', 'الشارقة', 'Sharjah', 25.3463, 55.4209),
  City('ae', 'al-ain', 'العين', 'Al Ain', 24.2075, 55.7447),
  City('ae', 'ras-al-khaimah', 'رأس الخيمة', 'Ras Al Khaimah', 25.8007, 55.9762),
  City('kw', 'kuwait-city', 'الكويت', 'Kuwait City', 29.3759, 47.9774),
  City('kw', 'jahra', 'الجهراء', 'Jahra', 29.3375, 47.6581),
  City('qa', 'doha', 'الدوحة', 'Doha', 25.2854, 51.5310),
  City('qa', 'al-khor', 'الخور', 'Al Khor', 25.6839, 51.5058),
  City('bh', 'manama', 'المنامة', 'Manama', 26.2285, 50.5860),
  City('bh', 'muharraq', 'المحرق', 'Muharraq', 26.2572, 50.6119),
  City('om', 'muscat', 'مسقط', 'Muscat', 23.5880, 58.3829),
  City('om', 'salalah', 'صلالة', 'Salalah', 17.0151, 54.0924),
  City('om', 'sohar', 'صحار', 'Sohar', 24.3470, 56.7094),
  City('om', 'nizwa', 'نزوى', 'Nizwa', 22.9333, 57.5333),
  City('jo', 'amman', 'عمّان', 'Amman', 31.9454, 35.9284),
  City('jo', 'irbid', 'إربد', 'Irbid', 32.5556, 35.8500),
  City('jo', 'zarqa', 'الزرقاء', 'Zarqa', 32.0728, 36.0880),
  City('jo', 'aqaba', 'العقبة', 'Aqaba', 29.5321, 35.0063),
  City('eg', 'cairo', 'القاهرة', 'Cairo', 30.0444, 31.2357),
  City('eg', 'alexandria', 'الإسكندرية', 'Alexandria', 31.2001, 29.9187),
  City('eg', 'giza', 'الجيزة', 'Giza', 30.0131, 31.2089),
  City('eg', 'port-said', 'بورسعيد', 'Port Said', 31.2653, 32.3019),
  City('eg', 'asyut', 'أسيوط', 'Asyut', 27.1809, 31.1837),
  City('eg', 'luxor', 'الأقصر', 'Luxor', 25.6872, 32.6396),
  City('eg', 'aswan', 'أسوان', 'Aswan', 24.0889, 32.8998),
  City('sy', 'damascus', 'دمشق', 'Damascus', 33.5138, 36.2765),
  City('sy', 'aleppo', 'حلب', 'Aleppo', 36.2021, 37.1343),
  City('sy', 'homs', 'حمص', 'Homs', 34.7324, 36.7137),
  City('sy', 'latakia', 'اللاذقية', 'Latakia', 35.5317, 35.7901),
  City('sy', 'deir-ez-zor', 'دير الزور', 'Deir ez-Zor', 35.3359, 40.1408),
  City('ps', 'jerusalem', 'القدس', 'Jerusalem', 31.7683, 35.2137),
  City('ps', 'gaza', 'غزة', 'Gaza', 31.5017, 34.4668),
  City('ps', 'ramallah', 'رام الله', 'Ramallah', 31.9038, 35.2034),
  City('ps', 'nablus', 'نابلس', 'Nablus', 32.2211, 35.2544),
  City('ps', 'hebron', 'الخليل', 'Hebron', 31.5326, 35.0998),
  City('iq', 'baghdad', 'بغداد', 'Baghdad', 33.3152, 44.3661),
  City('iq', 'basra', 'البصرة', 'Basra', 30.5085, 47.7804),
  City('iq', 'mosul', 'الموصل', 'Mosul', 36.3350, 43.1189),
  City('iq', 'erbil', 'أربيل', 'Erbil', 36.1911, 44.0092),
  City('iq', 'najaf', 'النجف', 'Najaf', 32.0259, 44.3462),
  City('iq', 'karbala', 'كربلاء', 'Karbala', 32.6160, 44.0249),
  City('ye', 'sanaa', 'صنعاء', "Sana'a", 15.3694, 44.1910),
  City('ye', 'aden', 'عدن', 'Aden', 12.7855, 45.0187),
  City('ye', 'taiz', 'تعز', 'Taiz', 13.5795, 44.0209),
  City('ye', 'hodeidah', 'الحديدة', 'Hodeidah', 14.7978, 42.9545),
  City('ye', 'mukalla', 'المكلا', 'Mukalla', 14.5425, 49.1242),
  City('lb', 'beirut', 'بيروت', 'Beirut', 33.8938, 35.5018),
  City('lb', 'tripoli', 'طرابلس', 'Tripoli', 34.4367, 35.8497),
  City('lb', 'sidon', 'صيدا', 'Sidon', 33.5571, 35.3729),
  City('lb', 'tyre', 'صور', 'Tyre', 33.2705, 35.2038),
];

/// مدن دولة معيّنة (قد تكون فارغة لدولة أُضيفت من الخادم بعد إصدار التطبيق).
List<City> citiesOf(String countryCode) =>
    [for (final c in kCities) if (c.countryCode == countryCode) c];

/// المدينة ذات المعرّف [id] (`sa/riyadh`) أو null.
City? cityById(String? id) {
  if (id == null) return null;
  for (final c in kCities) {
    if (c.id == id) return c;
  }
  return null;
}
