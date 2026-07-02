import 'package:flutter_test/flutter_test.dart';
import 'package:timer_grobi/core/qibla.dart';

void main() {
  group('qibla — اتجاه القبلة (سمت من الشمال الحقيقي)', () {
    test('الرياض ≈ ٢٤٥°', () {
      expect(qiblaBearing(24.7136, 46.6753), inInclusiveRange(243.0, 248.0));
    });

    test('القاهرة ≈ ١٣٦°', () {
      expect(qiblaBearing(30.0444, 31.2357), inInclusiveRange(133.0, 139.0));
    });

    test('إسطنبول ≈ ١٥١°', () {
      expect(qiblaBearing(41.0082, 28.9784), inInclusiveRange(148.0, 154.0));
    });

    test('جاكرتا ≈ ٢٩٥°', () {
      expect(qiblaBearing(-6.2088, 106.8456), inInclusiveRange(292.0, 298.0));
    });

    test('النتيجة دائماً ضمن [0, 360)', () {
      final b = qiblaBearing(-33.8688, 151.2093); // سيدني
      expect(b, inInclusiveRange(0.0, 360.0));
      expect(b, lessThan(360.0));
    });
  });

  group('qibla — المسافة إلى الكعبة', () {
    test('من مكة نفسها ≈ ٠ كم', () {
      expect(distanceToKaabaKm(kaabaLat, kaabaLng), lessThan(1.0));
    });

    test('الرياض ≈ ٧٩٠ كم (مسافة الدائرة العظمى)', () {
      expect(distanceToKaabaKm(24.7136, 46.6753),
          inInclusiveRange(760.0, 820.0));
    });

    test('القاهرة ≈ ١٢٩٤ كم', () {
      expect(distanceToKaabaKm(30.0444, 31.2357),
          inInclusiveRange(1200.0, 1400.0));
    });
  });
}
