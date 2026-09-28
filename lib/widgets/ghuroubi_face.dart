import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/ghuroubi_clock.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// وجه الساعة الغروبية: قوس يمثّل انقضاء اليوم الغروبي، المغرب عند الأعلى (12).
class GhuroubiFace extends StatelessWidget {
  final GhuroubiClock clock;
  const GhuroubiFace({super.key, required this.clock});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      // عزل الرسم عن أي إعادة رسم للمحيط، وتقليل تكلفة تحديث القوس.
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FacePainter(clock),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  clock.isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                  color: AppColors.gold,
                  size: 30,
                ),
                const SizedBox(height: 6),
                Text(
                  clock.format(),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onDark,
                    height: 1.0,
                  ),
                ),
                Text(
                  clock.isDaytime ? context.l10n.faceDay : context.l10n.faceNight,
                  style: const TextStyle(fontSize: 18, color: AppColors.gold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final GhuroubiClock clock;
  _FacePainter(this.clock);

  // تدرّج القوس ثابت — يُنشأ مرة واحدة بدل كل رسمة.
  static const _arcGradient = SweepGradient(
    startAngle: -math.pi / 2,
    colors: [AppColors.gold, Color(0xFFE08A3C)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;

    // الحلقة الخلفية
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = AppColors.muted.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius, ring);

    // قوس الانقضاء (يبدأ من الأعلى = المغرب، باتجاه عقارب الساعة)
    final progress = clock.dayProgress.clamp(0.0, 1.0);
    final sweep = 2 * math.pi * progress;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = _arcGradient
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );

    // علامات الساعات الـ12
    final tick = Paint()..color = AppColors.onDark.withValues(alpha: 0.5);
    for (var i = 0; i < 12; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / 12);
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (radius - 4);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (radius + 4);
      tick.strokeWidth = i == 0 ? 3 : 1.5;
      canvas.drawLine(p1, p2, tick);
    }

    // رأس المؤشّر
    final headAngle = -math.pi / 2 + sweep;
    final head = center + Offset(math.cos(headAngle), math.sin(headAngle)) * radius;
    canvas.drawCircle(head, 6, Paint()..color = AppColors.onDark);
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.clock.dayProgress != clock.dayProgress ||
      old.clock.isDaytime != clock.isDaytime;
}
