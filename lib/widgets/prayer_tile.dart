import 'package:flutter/material.dart';

import '../core/format_utils.dart';
import '../core/ghuroubi_clock.dart';
import '../core/solar_time.dart';
import '../models/day_times.dart';
import '../theme.dart';

/// صف وقت واحد: الاسم + ثلاثة أعمدة (غروبي | زوالي | مدني)، مع تظليل الوقت
/// الحالي/القادم.
///
/// - **غروبي**: توقيت التطبيق المعتمد على الغروب (المغرب = ١٢:٠٠، يُحسب من
///   الغروب السابق: [yesterdayMaghrib] لأوقات النهار و[todayMaghrib] لِما بعده).
/// - **زوالي**: التوقيت الشمسي الحقيقي (الزوال = ١٢:٠٠) من خط الطول.
/// - **مدني**: وقت ساعة الجهاز المعروف.
class PrayerTile extends StatelessWidget {
  final PrayerKind kind;
  final DateTime time;
  final double longitude;
  final DateTime todayMaghrib;
  final DateTime yesterdayMaghrib;
  final bool isCurrent;
  final bool isNext;

  const PrayerTile({
    super.key,
    required this.kind,
    required this.time,
    required this.longitude,
    required this.todayMaghrib,
    required this.yesterdayMaghrib,
    this.isCurrent = false,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final solar = solarTime(time, longitude);

    // الوقت الغروبي: المنقضي منذ الغروب السابق (المغرب نفسه = ١٢:٠٠).
    final lastSunset =
        time.isBefore(todayMaghrib) ? yesterdayMaghrib : todayMaghrib;
    final ghuroubi = GhuroubiClock(
      sinceSunset: time.difference(lastSunset),
      untilNextSunset: Duration.zero,
      isDaytime: false,
    );

    final highlight = isCurrent || isNext;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.gold.withValues(alpha: 0.18)
            : AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: 0.12),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    kind.arabicName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.onDark,
                    ),
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.notifications_active,
                      size: 14, color: AppColors.gold),
                ],
              ],
            ),
          ),
          Expanded(flex: 2, child: _col('غروبي', toArabicDigits(ghuroubi.format()))),
          Expanded(
              flex: 2,
              child: _col('زوالي', fmt12FromHm(solar.hour, solar.minute))),
          Expanded(flex: 2, child: _col('مدني', fmt12(time))),
        ],
      ),
    );
  }

  Widget _col(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onDark)),
        ),
      ],
    );
  }
}
