import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/format_utils.dart';
import '../core/qibla.dart';
import '../providers/location_provider.dart';
import '../providers/time_providers.dart';
import '../theme.dart';

/// شاشة اتجاه القبلة: بوصلة حيّة تحسب اتجاه الجهاز من الحسّاس المغناطيسي والتسارع،
/// وتشير للكعبة اعتماداً على موقع المستخدم. عند غياب الحسّاس المغناطيسي تعرض
/// الاتجاه رقمياً (رسم ثابت شماله للأعلى).
class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _availabilityTimer;

  // آخر شعاع جاذبية من مقياس التسارع (لتعويض ميل الجهاز).
  double? _ax, _ay, _az;
  // مكوّنا الاتجاه المُنعّمان (متوسّط متحرّك على المتّجه لتفادي التفاف الزاوية).
  double _sinH = 0.0;
  double _cosH = 1.0;

  double? _headingDeg; // اتجاه أعلى الجهاز عن الشمال المغناطيسي، [0,360)
  bool _sensorMissing = false;

  @override
  void initState() {
    super.initState();
    _accelSub = accelerometerEventStream().listen(
      (e) {
        _ax = e.x;
        _ay = e.y;
        _az = e.z;
      },
      onError: (_) {},
      cancelOnError: false,
    );
    _magSub = magnetometerEventStream().listen(
      _onMagnetometer,
      onError: (_) => _markMissing(),
      cancelOnError: false,
    );
    // إن لم تصل قراءة خلال ثلاث ثوانٍ نعتبر الحسّاس غير متوفّر.
    _availabilityTimer = Timer(const Duration(seconds: 3), _markMissing);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _availabilityTimer?.cancel();
    super.dispose();
  }

  void _markMissing() {
    if (mounted && _headingDeg == null) {
      setState(() => _sensorMissing = true);
    }
  }

  void _onMagnetometer(MagnetometerEvent m) {
    final ax = _ax, ay = _ay, az = _az;
    if (ax == null || ay == null || az == null) return;
    final heading = _computeHeading(ax, ay, az, m.x, m.y, m.z);
    if (heading == null) return;

    // تنعيم عبر متوسّط أسّي على (جا، جتا) لتجنّب قفزة ٣٥٩°→٠°.
    const alpha = 0.15;
    final rad = heading * math.pi / 180.0;
    _sinH += alpha * (math.sin(rad) - _sinH);
    _cosH += alpha * (math.cos(rad) - _cosH);
    final smoothed =
        (math.atan2(_sinH, _cosH) * 180.0 / math.pi + 360.0) % 360.0;

    if (mounted) {
      setState(() {
        _headingDeg = smoothed;
        _sensorMissing = false;
      });
    }
  }

  /// اتجاه أعلى الجهاز عن الشمال المغناطيسي بالدرجات، بطريقة مصفوفة الدوران
  /// القياسية (getRotationMatrix/getOrientation في أندرويد). تعيد null إذا
  /// تعذّر الحساب (مثلاً محاذاة المتّجهين).
  double? _computeHeading(
      double ax, double ay, double az, double ex, double ey, double ez) {
    // H = E × A  (شرق الجهاز)
    var hx = ey * az - ez * ay;
    var hy = ez * ax - ex * az;
    var hz = ex * ay - ey * ax;
    final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
    if (normH < 0.1) return null;
    final invH = 1.0 / normH;
    hx *= invH;
    hy *= invH;
    hz *= invH;

    final invA = 1.0 / math.sqrt(ax * ax + ay * ay + az * az);
    final axn = ax * invA, azn = az * invA;

    // M = A × H  (شمال الجهاز) — نحتاج مكوّن Y فقط.
    final my = azn * hx - axn * hz;
    // السمت = atan2(R[1], R[4]) = atan2(Hy, My)
    final azimuth = math.atan2(hy, my);
    return (azimuth * 180.0 / math.pi + 360.0) % 360.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDaytime =
        ref.watch(ghuroubiNowProvider.select((g) => g.clock.isDaytime));
    final loc = ref.watch(locationProvider);
    final bearing = qiblaBearing(loc.latitude, loc.longitude);

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient(isDaytime)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('القبلة',
              style: TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          top: false,
          child: _buildBody(bearing),
        ),
      ),
    );
  }

  Widget _buildBody(double bearing) {
    // لا حسّاس مغناطيسي — عرض رقمي ثابت (الشمال للأعلى).
    if (_sensorMissing) {
      return _QiblaBody(
        headingDeg: 0,
        bearingDeg: bearing,
        aligned: false,
        note: 'جهازك لا يحتوي حسّاساً مغناطيسياً للبوصلة، '
            'لذا نعرض اتجاه القبلة رقمياً (الشمال للأعلى).',
      );
    }
    // بانتظار أوّل قراءة من الحسّاس.
    final heading = _headingDeg;
    if (heading == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    // الفرق الزاوي بين اتجاه الجهاز واتجاه القبلة (لتلوين «تواجه القبلة»).
    final diff = (((bearing - heading) + 540) % 360) - 180;
    final aligned = diff.abs() < 5;
    return _QiblaBody(
      headingDeg: heading,
      bearingDeg: bearing,
      aligned: aligned,
      hint: aligned ? 'أنت تواجه القبلة' : 'أدِر جهازك حتى يشير السهم للأعلى',
    );
  }
}

/// جسم الشاشة: البوصلة + التلميح + بطاقتا الاتجاه والمسافة + زر تحديث الموقع.
class _QiblaBody extends ConsumerWidget {
  final double headingDeg; // اتجاه الجهاز (٠ للعرض الثابت)
  final double bearingDeg; // اتجاه القبلة من الشمال الحقيقي
  final bool aligned;
  final String? hint;
  final String? note;

  const _QiblaBody({
    required this.headingDeg,
    required this.bearingDeg,
    required this.aligned,
    this.hint,
    this.note,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(locationProvider);
    final distKm = distanceToKaabaKm(loc.latitude, loc.longitude);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          _CompassView(
              headingDeg: headingDeg, bearingDeg: bearingDeg, aligned: aligned),
          if (note != null) ...[
            const SizedBox(height: 8),
            const Text('الشمال للأعلى ↑',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          if (hint != null)
            Text(
              hint!,
              style: TextStyle(
                color: aligned ? const Color(0xFF57C271) : AppColors.muted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (hint != null) const SizedBox(height: 20),
          _factCard(Icons.explore_outlined, 'اتجاه القبلة',
              '${toArabicDigits(bearingDeg.round().toString())}° من الشمال'),
          const SizedBox(height: 10),
          _factCard(Icons.straighten, 'المسافة إلى الكعبة',
              '${toArabicDigits(distKm.round().toString())} كم'),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                ref.read(locationProvider.notifier).refreshFromGps(),
            icon: const Icon(Icons.my_location, size: 18, color: AppColors.gold),
            label: const Text('تحديث موقعي',
                style: TextStyle(color: AppColors.gold)),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.muted, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(note!,
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _factCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.onDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// قرص البوصلة (دائرة + علامات + N/E/S/W) وسهم القبلة فوقه.
///
/// القرص يدور بمقدار −heading ليبقى الشمال في مكانه الحقيقي، وسهم القبلة يدور
/// بمقدار (bearing − heading) فيشير للكعبة؛ ومحاذاته للأعلى تعني مواجهتها.
class _CompassView extends StatelessWidget {
  final double headingDeg;
  final double bearingDeg;
  final bool aligned;

  const _CompassView({
    required this.headingDeg,
    required this.bearingDeg,
    required this.aligned,
  });

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    final needleColor = aligned ? const Color(0xFF57C271) : AppColors.gold;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -headingDeg * math.pi / 180.0,
            child: CustomPaint(
              size: const Size(size, size),
              painter: _DialPainter(),
            ),
          ),
          Transform.rotate(
            angle: (bearingDeg - headingDeg) * math.pi / 180.0,
            child: SizedBox(
              width: size,
              height: size,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Icon(Icons.navigation, size: 58, color: needleColor),
                ),
              ),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
                color: AppColors.gold, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// رسّام قرص البوصلة: حلقة خارجية + علامات كل ٥° + حروف الجهات الأربع.
class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.gold.withValues(alpha: 0.5),
    );

    final tick = Paint()..color = AppColors.muted;
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180.0;
      final major = i % 6 == 0; // كل ٣٠°
      final len = major ? 12.0 : 6.0;
      final dir = Offset(math.sin(a), -math.cos(a));
      tick.strokeWidth = major ? 2 : 1;
      canvas.drawLine(
          center + dir * (radius - 2), center + dir * (radius - 2 - len), tick);
    }

    _label(canvas, size, 'N', 0, AppColors.gold);
    _label(canvas, size, 'E', 90, AppColors.onDark);
    _label(canvas, size, 'S', 180, AppColors.onDark);
    _label(canvas, size, 'W', 270, AppColors.onDark);
  }

  void _label(Canvas canvas, Size size, String text, double deg, Color color) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final a = deg * math.pi / 180.0;
    final pos = center + Offset(math.sin(a), -math.cos(a)) * (radius - 30);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Cairo',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
