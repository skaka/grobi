import 'dart:math' as math;

/// إحداثيات الكعبة المشرّفة (المسجد الحرام، مكة المكرمة).
const double kaabaLat = 21.4225;
const double kaabaLng = 39.8262;

/// نصف قطر الأرض المتوسّط بالكيلومترات (لصيغة هافرساين).
const double _earthRadiusKm = 6371.0;

double _deg2rad(double d) => d * math.pi / 180.0;
double _rad2deg(double r) => r * 180.0 / math.pi;

/// اتجاه القبلة (سمت الدائرة العظمى نحو الكعبة) بالدرجات من الشمال الحقيقي،
/// في المجال `[0, 360)` حيث ٠° = شمال و٩٠° = شرق.
///
/// θ = atan2( sin Δλ·cos φ₂ , cos φ₁·sin φ₂ − sin φ₁·cos φ₂·cos Δλ )
/// حيث φ₁ خط عرض المستخدم، φ₂ خط عرض الكعبة، Δλ = خط طول الكعبة − خط طول المستخدم.
///
/// أمثلة محقّقة: من مكة نفسها ⇒ ~٠ ؛ من الرياض (24.7،46.7) ⇒ ~٢٥٥° ؛
/// من القاهرة (30،31.2) ⇒ ~١٣٦°.
double qiblaBearing(double latDeg, double lngDeg) {
  final phi1 = _deg2rad(latDeg);
  final phi2 = _deg2rad(kaabaLat);
  final dLambda = _deg2rad(kaabaLng - lngDeg);
  final y = math.sin(dLambda) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
  final bearing = _rad2deg(math.atan2(y, x));
  return (bearing + 360.0) % 360.0;
}

/// المسافة إلى الكعبة بالكيلومترات (صيغة هافرساين على كرة).
double distanceToKaabaKm(double latDeg, double lngDeg) {
  final phi1 = _deg2rad(latDeg);
  final phi2 = _deg2rad(kaabaLat);
  final dPhi = _deg2rad(kaabaLat - latDeg);
  final dLambda = _deg2rad(kaabaLng - lngDeg);
  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(dLambda / 2) *
          math.sin(dLambda / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusKm * c;
}

/// اتجاه أعلى الجهاز عن الشمال **الحقيقي** من اتجاهه المغناطيسي [magneticDeg]
/// والانحراف المغناطيسي المحلي [declinationDeg] (شرقاً موجب)، في `[0, 360)`.
///
/// البوصلة تقيس المغناطيسي و[qiblaBearing] حقيقي؛ الفرق في المنطقة ٢–٥° (وأكثر
/// في أطرافها)، فبدون التصحيح قد يُعلَن «تواجه القبلة» والمستخدم منحرف ~٩°.
double trueHeading(double magneticDeg, double declinationDeg) =>
    ((magneticDeg + declinationDeg) % 360.0 + 360.0) % 360.0;

/// الزاوية الموقَّعة من اتجاه الجهاز إلى القبلة، في `(−180, 180]` (موجبة = القبلة
/// إلى اليمين).
double angleToQibla(double headingDeg, double bearingDeg) {
  final d = ((bearingDeg - headingDeg) % 360.0 + 360.0) % 360.0;
  return d > 180.0 ? d - 360.0 : d;
}

/// شدّة المجال الأرضي بين ~٢٥ و~٦٥ ميكروتسلا في كل مكان؛ ما خرج عن مدى مريح
/// حولها يعني تشويشاً قريباً (معادن، مغناطيس الغطاء) أو بوصلة تحتاج معايرة.
bool magneticFieldSuspicious(double x, double y, double z) {
  final microtesla = math.sqrt(x * x + y * y + z * z);
  return microtesla < 20.0 || microtesla > 75.0;
}
