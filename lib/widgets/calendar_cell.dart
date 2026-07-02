import 'package:flutter/material.dart';

import '../core/format_utils.dart';
import '../theme.dart';

/// خلية يوم في التقويم: الميلادي (صغير) + الهجري الغروبي (كبير).
class CalendarCell extends StatelessWidget {
  final int gregorianDay;
  final int hijriDay;
  final bool isToday;
  final bool isFriday;
  final VoidCallback onTap;

  const CalendarCell({
    super.key,
    required this.gregorianDay,
    required this.hijriDay,
    required this.isToday,
    required this.isFriday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.gold.withValues(alpha: 0.25)
              : AppColors.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.1),
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              toArabicDigits('$hijriDay'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isFriday ? AppColors.gold : AppColors.onDark,
              ),
            ),
            Text(
              toArabicDigits('$gregorianDay'),
              style: const TextStyle(fontSize: 11, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
