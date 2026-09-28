import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../core/date_utils.dart';
import '../core/format_utils.dart';
import '../core/umm_alqura_corrections.dart';
import '../l10n/l10n.dart';
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

  // ترتيب الأعمدة يبدأ بالسبت ([DateTime.weekday]: السبت=6 … الجمعة=5).
  static const _columnWeekdays = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  void _shiftMonth(int delta) => setState(() => _monthOffset += delta);

  @override
  Widget build(BuildContext context) {
    // التقويم هجري‑الأساس: الشبكة شهر هجري كامل، والميلادي هو المنقسم.
    final adjustments = ref.watch(hijriAdjustmentsProvider);
    final manualAdjust = ref.watch(settingsProvider.select((s) => s.hijriAdjust));
    // «اليوم» هو اليوم الغروبي (يتقدّم عند المغرب) كما في شاشة الساعة، ويتحدّث مع
    // نبضة الدقيقة — لا `DateTime.now()` وقت البناء الذي لا يتبع الغروب ولا منتصف الليل.
    final today = ref.watch(ghuroubiNowProvider.select((g) => g.ghuroubiCivilDate));

    // شهر اليوم الهجري (المُصحَّح) + الإزاحة ⇒ الشهر المعروض.
    final todayH = correctedHijri(today, adjustments, manualAdjust: manualAdjust);
    final ordinal = todayH.hYear * 12 + (todayH.hMonth - 1) + _monthOffset;
    final hYear = ordinal ~/ 12;
    final hMonth = ordinal % 12 + 1;

    // أيام الشهر الميلادية كما يراها التطبيق (مع الإزاحة اليدوية) — بأيام تقويمية.
    final grid =
        hijriMonthGrid(hYear, hMonth, adjustments, manualAdjust: manualAdjust);
    final headerHijri =
        correctedHijri(grid.start, adjustments, manualAdjust: manualAdjust);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(headerHijri, grid.start, grid.end),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final weekday in _columnWeekdays)
                Expanded(
                  child: Center(
                    child: Text(weekdayShort(weekday),
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
              for (var i = 0; i < grid.leadingFromSaturday; i++)
                const SizedBox.shrink(),
              for (var i = 0; i < grid.days.length; i++)
                _buildCell(i + 1, grid.days[i], today),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.calendarHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
      gregText = localDigits('${gregorianMonthName(start.month)} ${start.year}');
    } else if (start.year == end.year) {
      gregText = localDigits('${gregorianMonthName(start.month)} / '
          '${gregorianMonthName(end.month)} ${start.year}');
    } else {
      gregText = localDigits('${gregorianMonthName(start.month)} ${start.year} / '
          '${gregorianMonthName(end.month)} ${end.year}');
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
              localDigits('${hijriMonthName(headerHijri.hMonth)} '
                  '${headerHijri.hYear} $hijriEra'),
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
      isToday: isSameDate(gregDate, today),
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
            final yesterdayTimes =
                sheetRef.watch(prayerDayProvider(addDays(date, -1)));
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
                    localDigits('${date.day} ${gregorianMonthName(date.month)} — '
                        '${hijri.hDay} ${hijriMonthName(hijri.hMonth)}'),
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
