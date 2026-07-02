import 'dart:math' as math;

/// حسابات فلكية شمسية عالية الدقّة (خوارزمية Meeus، الفصلان 25 و28).
/// دقّة الميل ~ ثوانٍ قوسية، ومعادلة الزمن ~ أقل من ثانية على مدار السنة.
///
/// تُستخدم في:
/// - [solarTime] لحساب التوقيت الزوالي (الشمسي الحقيقي) عبر [equationOfTime].
/// - تصحيح الارتفاع (عبر [hourAngle] و[solarDeclination]).
///
/// كل الزوايا بالدرجات، والأزمنة بالـ UTC.

const double _deg2rad = math.pi / 180.0;
const double _rad2deg = 180.0 / math.pi;

double _sinD(double deg) => math.sin(deg * _deg2rad);
double _cosD(double deg) => math.cos(deg * _deg2rad);

/// عدد القرون اليوليانية منذ حقبة J2000.0 (2000-01-01 12:00 UTC).
double _julianCenturies(DateTime instant) {
  final jd = instant.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  return (jd - 2451545.0) / 36525.0;
}

double _normalize360(double deg) {
  final r = deg % 360.0;
  return r < 0 ? r + 360.0 : r;
}

double _normalize180(double deg) {
  var r = (deg + 180.0) % 360.0;
  if (r < 0) r += 360.0;
  return r - 180.0;
}

/// خط طول الشمس المتوسط ومطلعها المستقيم وميلها لِلحظة معيّنة (دقّة Meeus).
class _SunPosition {
  final double meanLongitude; // L0 (deg)
  final double rightAscension; // α (deg)
  final double declination; // δ (deg)
  const _SunPosition(this.meanLongitude, this.rightAscension, this.declination);
}

_SunPosition _sunPosition(DateTime instant) {
  final t = _julianCenturies(instant);

  // خط الطول المتوسط L0 والشذوذ المتوسط M (درجات).
  final l0 = _normalize360(280.46646 + 36000.76983 * t + 0.0003032 * t * t);
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;

  // معادلة المركز C (حدود Meeus العليا).
  final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sinD(m) +
      (0.019993 - 0.000101 * t) * _sinD(2 * m) +
      0.000289 * _sinD(3 * m);

  // خط الطول الحقيقي ⊙ ثم الظاهري λ (تصحيح التغذّي والزيغ الضوئي).
  final trueLong = l0 + c;
  final omega = 125.04 - 1934.136 * t;
  final lambda = trueLong - 0.00569 - 0.00478 * _sinD(omega);

  // ميل دائرة البروج ε (متوسط + تصحيح التغذّي).
  final eps0 = 23.439291 -
      (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0;
  final epsilon = eps0 + 0.00256 * _cosD(omega);

  final declination = math.asin(_sinD(epsilon) * _sinD(lambda)) * _rad2deg;
  var alpha =
      math.atan2(_cosD(epsilon) * _sinD(lambda), _cosD(lambda)) * _rad2deg;
  alpha = _normalize360(alpha);

  return _SunPosition(l0, alpha, declination);
}

/// ميل الشمس δ بالدرجات للحظة [instant].
double solarDeclination(DateTime instant) => _sunPosition(instant).declination;

/// معادلة الزمن (EoT) بالدقائق: الفرق بين الزمن الشمسي الظاهري والمتوسط
/// (Meeus 28.1): `E = L0 − 0.0057183° − α`، تُردّ إلى [−180,180] ثم ×4 دقيقة/درجة.
/// المدى ~ −14 إلى +16 دقيقة على مدار السنة.
double equationOfTime(DateTime instant) {
  final p = _sunPosition(instant);
  final diff = _normalize180(p.meanLongitude - 0.0057183 - p.rightAscension);
  return diff * 4.0;
}

/// الزاوية الساعية H (بالدرجات) التي تصل عندها الشمس إلى زاوية انخفاض
/// [depressionDeg] تحت الأفق، عند خط العرض [latDeg] وميل الشمس [declDeg].
///
/// تُعيد [double.nan] إذا كانت الشمس لا تبلغ تلك الزاوية إطلاقاً
/// (مناطق قطبية / شمس لا تغيب أو لا تشرق).
double hourAngle(double depressionDeg, double latDeg, double declDeg) {
  final cosH = (_sinD(-depressionDeg) - _sinD(latDeg) * _sinD(declDeg)) /
      (_cosD(latDeg) * _cosD(declDeg));
  if (cosH < -1.0 || cosH > 1.0) return double.nan;
  return math.acos(cosH) * _rad2deg;
}
