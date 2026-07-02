import 'dart:math' as math;

import 'astronomy.dart';

/// زاوية انخفاض الأفق القياسية للشروق/الغروب عند سطح البحر (نصف القطر + الانكسار).
const double standardHorizonAngle = 0.833;

/// تصحيح الارتفاع عن سطح البحر (انخفاض الأفق) محسوباً كفرق زمني بالدقائق.
///
/// على ارتفاع [altitudeMeters] يهبط الأفق المرئي بزاوية `dip = 0.0347·√h` درجة،
/// فتتأخّر أحداث الغروب وتتقدّم أحداث الشروق. نحسب الفرق الزمني عبر فرق الزاوية
/// الساعية بين الزاويتين (تتلاشى حدود الزوال/المنطقة الزمنية في الفرق، فلا نحتاج
/// سوى خط العرض وميل الشمس).
///
/// تُعيد قيمة ≥ 0 بالدقائق. تُعيد 0 إذا كان الارتفاع ≤ 0 أو إذا تعذّر الحساب
/// (مناطق قطبية: الشمس لا تبلغ زاوية الأفق).
///
/// أمثلة محقّقة: h=0 ⇒ 0 ؛ مكة (φ≈21.4، h=277) ⇒ ~2.7د ؛ h=1000 ⇒ ~5د.
double elevationDeltaMinutes(double latDeg, DateTime date, double altitudeMeters) {
  if (altitudeMeters <= 0) return 0.0;
  final decl = solarDeclination(date.toUtc());
  final dip = 0.0347 * math.sqrt(altitudeMeters);
  final h0 = hourAngle(standardHorizonAngle, latDeg, decl);
  final h1 = hourAngle(standardHorizonAngle + dip, latDeg, decl);
  if (h0.isNaN || h1.isNaN) return 0.0;
  return (h1 - h0) / 15.0 * 60.0;
}
