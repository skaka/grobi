import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/cities.dart';
import 'package:timer_grobi/core/countries.dart';
import 'package:timer_grobi/core/format_utils.dart';
import 'package:timer_grobi/models/location_data.dart';

void main() {
  group('LocationData', () {
    test('الافتراضي ليس «يدوياً» بل احتياطي (مكة) بلا ارتفاع', () {
      expect(LocationData.fallback.isFallback, isTrue);
      expect(LocationData.fallback.isManual, isFalse);
      expect(LocationData.fallback.altitude, 0);
      expect(cityById(LocationData.fallback.cityId)?.nameEn, 'Mecca');
    });

    test('الصيغة المخزّنة القديمة (isManual) تُقرأ', () {
      final gps = LocationData.fromJson({
        'latitude': 24.7,
        'longitude': 46.7,
        'altitude': 612.0,
        'isManual': false,
      });
      expect(gps.source, LocationSource.gps);
      final manual = LocationData.fromJson(
          {'latitude': 24.7, 'longitude': 46.7, 'isManual': true});
      expect(manual.source, LocationSource.manual);
    });

    test('ذهاب/عودة مع المصدر ومعرّف المدينة', () {
      const loc = LocationData(
          latitude: 30.0444,
          longitude: 31.2357,
          source: LocationSource.manual,
          cityId: 'eg/cairo');
      expect(LocationData.fromJson(loc.toJson()), loc);
    });
  });

  group('إدخال الأرقام', () {
    test('أرقام عربية وفارسية وفواصل مختلفة', () {
      expect(parseLocalizedDouble('٢٤٫٧١٣٦'), 24.7136);
      expect(parseLocalizedDouble('۴۶.۶۷'), 46.67);
      expect(parseLocalizedDouble(' 46,6753 '), 46.6753);
      expect(parseLocalizedDouble('-7.5898'), -7.5898);
      expect(parseLocalizedDouble('−7.5'), -7.5);
      expect(parseLocalizedDouble('abc'), isNull);
      expect(parseLocalizedDouble(''), isNull);
    });
  });

  group('المدن المضمَّنة', () {
    test('معرّفات المدن فريدة ولكل مدينة اسم إنجليزي', () {
      final ids = kCities.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(kCities.where((c) => c.nameEn.trim().isEmpty), isEmpty);
      expect(cityById('sa/riyadh')?.nameAr, 'الرياض');
      expect(cityById('xx/none'), isNull);
    });

    test('لكل دولة مضمَّنة مدينتان على الأقل، بإحداثيات معقولة', () {
      for (final c in kCountries) {
        expect(citiesOf(c.code).length, greaterThanOrEqualTo(2),
            reason: c.code);
      }
      for (final city in kCities) {
        expect(kCountries.any((c) => c.code == city.countryCode), isTrue);
        // النطاق الجغرافي للدول الثلاث عشرة (اليمن جنوباً → سوريا شمالاً).
        expect(city.latitude, inInclusiveRange(12, 38), reason: city.nameAr);
        expect(city.longitude, inInclusiveRange(29, 60), reason: city.nameAr);
      }
    });
  });
}
