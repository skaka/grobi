import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format_utils.dart';
import '../models/day_times.dart';
import '../providers/location_provider.dart';
import '../providers/time_providers.dart';
import '../theme.dart';
import '../widgets/prayer_tile.dart';

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الجسم يتحدّث كل دقيقة فقط؛ العدّاد التنازلي بالثواني في widget مستقل أدناه.
    final now = ref.watch(minuteTickerProvider);
    final today0 = dateOnly(now);
    final today = ref.watch(prayerDayProvider(today0));
    final yesterday =
        ref.watch(prayerDayProvider(today0.subtract(const Duration(days: 1))));
    final tomorrow =
        ref.watch(prayerDayProvider(today0.add(const Duration(days: 1))));
    final loc = ref.watch(locationProvider);

    final next = _nextPrayer(now, today, tomorrow);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('مواقيت الصلاة',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 12),
          _PrayerCountdown(next),
          const SizedBox(height: 16),
          for (final entry in today.ordered)
            PrayerTile(
              kind: entry.key,
              time: entry.value,
              longitude: loc.longitude,
              todayMaghrib: today.maghrib,
              yesterdayMaghrib: yesterday.maghrib,
              isNext: entry.key == next.kind && _isToday(next.time, today0),
            ),
        ],
      ),
    );
  }

  _NextPrayer _nextPrayer(DateTime now, DayTimes today, DayTimes tomorrow) {
    final salah = [
      MapEntry(PrayerKind.fajr, today.fajr),
      MapEntry(PrayerKind.dhuhr, today.dhuhr),
      MapEntry(PrayerKind.asr, today.asr),
      MapEntry(PrayerKind.maghrib, today.maghrib),
      MapEntry(PrayerKind.isha, today.isha),
    ];
    for (final e in salah) {
      if (e.value.isAfter(now)) return _NextPrayer(e.key, e.value);
    }
    return _NextPrayer(PrayerKind.fajr, tomorrow.fajr); // فجر الغد
  }

  bool _isToday(DateTime t, DateTime today0) =>
      dateOnly(t) == today0;
}

class _NextPrayer {
  final PrayerKind kind;
  final DateTime time;
  const _NextPrayer(this.kind, this.time);
}

/// عدّاد «الصلاة القادمة» — يراقب نبضة الثانية وحده فلا يُعيد بناء قائمة المواقيت
/// والضوابط كل ثانية. [next] يأتي من جسم الشاشة (يتحدّث كل دقيقة).
class _PrayerCountdown extends ConsumerWidget {
  final _NextPrayer next;
  const _PrayerCountdown(this.next);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(secondTickerProvider);
    final remaining = next.time.difference(now);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0.25),
          AppColors.gold.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('الصلاة القادمة: ${next.kind.arabicName}',
              style: const TextStyle(fontSize: 16, color: AppColors.onDark)),
          const SizedBox(height: 4),
          Text(formatDuration(remaining.isNegative ? Duration.zero : remaining),
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.gold)),
        ],
      ),
    );
  }
}
