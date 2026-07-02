import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/format_utils.dart';
import '../core/umm_alqura_corrections.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/time_providers.dart';
import '../theme.dart';
import '../widgets/calendar_cell.dart';
import '../widgets/date_tools_cards.dart';
import '../widgets/prayer_tile.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int _monthOffset = 0; // إزاحة بالأشهر الهجرية عن شهر اليوم

  // ترتيب الأعمدة يبدأ بالسبت.
  static const _weekdayLabels = ['سبت', 'أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع'];

  void _shiftMonth(int delta) => setState(() => _monthOffset += delta);

  @override
  Widget build(BuildContext context) {
    // التقويم هجري‑الأساس: الشبكة شهر هجري كامل، والميلادي هو المنقسم.
    final adjustments = ref.watch(hijriAdjustmentsProvider);
    final manualAdjust = ref.watch(settingsProvider.select((s) => s.hijriAdjust));
    final today = dateOnly(DateTime.now());

    // شهر اليوم الهجري (المُصحَّح) + الإزاحة ⇒ الشهر المعروض.
    final todayH = correctedHijri(today, adjustments, manualAdjust: manualAdjust);
    final ordinal = todayH.hYear * 12 + (todayH.hMonth - 1) + _monthOffset;
    final hYear = ordinal ~/ 12;
    final hMonth = ordinal % 12 + 1;

    // بداية الشهر الميلادية كما يراها التطبيق (مع الإزاحة اليدوية) وطوله.
    final start = correctedMonthStart(hYear, hMonth, adjustments)
        .subtract(Duration(days: manualAdjust));
    final len = correctedMonthLength(hYear, hMonth, adjustments);
    final leading = (start.weekday - DateTime.saturday + 7) % 7;
    final end = start.add(Duration(days: len - 1));
    final headerHijri =
        correctedHijri(start, adjustments, manualAdjust: manualAdjust);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(headerHijri, start, end),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final lbl in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(lbl,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.78,
            children: [
              for (var i = 0; i < leading; i++) const SizedBox.shrink(),
              for (var day = 1; day <= len; day++)
                _buildCell(day, start.add(Duration(days: day - 1)), today),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'الرقم الكبير: هجري • الصغير: ميلادي — استخدم الأسهم لتغيير الشهر',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          const HijriConverterCard(),
          const SizedBox(height: 16),
          const DateDifferenceCard(),
        ],
      ),
    );
  }

  Widget _header(HijriCalendar headerHijri, DateTime start, DateTime end) {
    // الشهر الهجري يمتدّ على شهرين ميلاديين ⇒ نعرض اسمي الشهرين (والسنة/السنتين).
    final String gregText;
    if (start.month == end.month) {
      gregText =
          '${gregorianMonthAr(start.month)} ${toArabicDigits('${start.year}')}';
    } else if (start.year == end.year) {
      gregText =
          '${gregorianMonthAr(start.month)} / ${gregorianMonthAr(end.month)} ${toArabicDigits('${start.year}')}';
    } else {
      gregText =
          '${gregorianMonthAr(start.month)} ${toArabicDigits('${start.year}')} / ${gregorianMonthAr(end.month)} ${toArabicDigits('${end.year}')}';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left, color: AppColors.onDark),
        ),
        Column(
          children: [
            Text(
              '${headerHijri.longMonthName} ${toArabicDigits('${headerHijri.hYear}')} هـ',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onDark),
            ),
            Text(
              gregText,
              style: const TextStyle(fontSize: 13, color: AppColors.gold),
            ),
          ],
        ),
        IconButton(
          onPressed: () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right, color: AppColors.onDark),
        ),
      ],
    );
  }

  Widget _buildCell(int hijriDay, DateTime gregDate, DateTime today) {
    return CalendarCell(
      gregorianDay: gregDate.day,
      hijriDay: hijriDay,
      isToday: gregDate == today,
      isFriday: gregDate.weekday == DateTime.friday,
      onTap: () => _showDayTimes(gregDate),
    );
  }

  void _showDayTimes(DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final times = sheetRef.watch(prayerDayProvider(date));
            final yesterdayTimes = sheetRef
                .watch(prayerDayProvider(date.subtract(const Duration(days: 1))));
            final lon = sheetRef.watch(locationProvider).longitude;
            final adjustments = sheetRef.watch(hijriAdjustmentsProvider);
            final manualAdjust =
                sheetRef.watch(settingsProvider.select((s) => s.hijriAdjust));
            final hijri =
                correctedHijri(date, adjustments, manualAdjust: manualAdjust);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    toArabicDigits(
                        '${date.day} ${gregorianMonthAr(date.month)} — ${hijri.hDay} ${hijri.longMonthName}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in times.ordered)
                    PrayerTile(
                      kind: entry.key,
                      time: entry.value,
                      longitude: lon,
                      todayMaghrib: times.maghrib,
                      yesterdayMaghrib: yesterdayTimes.maghrib,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
