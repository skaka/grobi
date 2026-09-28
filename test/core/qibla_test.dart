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

  group('الشمال الحقيقي', () {
    test('الاتجاه الحقيقي = المغناطيسي + الانحراف (شرقاً موجب)', () {
      expect(trueHeading(100, 4), 104);
      expect(trueHeading(358, 4), closeTo(2, 1e-9));
      expect(trueHeading(2, -4), closeTo(358, 1e-9));
    });

    test('الزاوية إلى القبلة موقَّعة في (−180، 180]', () {
      expect(angleToQibla(0, 90), 90);
      expect(angleToQibla(90, 0), -90);
      expect(angleToQibla(350, 10), closeTo(20, 1e-9));
      expect(angleToQibla(10, 350), closeTo(-20, 1e-9));
      expect(angleToQibla(0, 180), 180);
    });

    test('بلا تصحيح كان «تواجه القبلة» يظهر والمستخدم منحرف ~٩°', () {
      // انحراف ٤° شرقاً، والمستخدم متّجه فعلياً إلى القبلة + ٨٫٥° (حدّ ±٥ القديم
      // + ٤ انحراف ⇒ حتى ~٩° كانت تُعدّ مواجهة).
      const bearing = 182.0, declination = 4.0;
      final magneticReading = bearing + 8.5 - declination; // ما تقرؤه البوصلة
      expect(angleToQibla(magneticReading, bearing).abs() < 5, isTrue,
          reason: 'المنطق القديم: يعدّه مواجهاً');
      expect(
          angleToQibla(trueHeading(magneticReading, declination), bearing)
                  .abs() <
              5,
          isFalse,
          reason: 'بالتصحيح: منحرف ٨٫٥°');
    });

    test('شدّة المجال خارج المدى الأرضي ⇒ تشويش', () {
      expect(magneticFieldSuspicious(0, 30, -30), isFalse); // ~٤٢ ميكروتسلا
      expect(magneticFieldSuspicious(0, 5, 5), isTrue); // ~٧
      expect(magneticFieldSuspicious(100, 100, 0), isTrue); // ~١٤١
    });
  });
}
