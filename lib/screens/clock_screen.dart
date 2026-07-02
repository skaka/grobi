import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format_utils.dart';
import '../models/ghuroubi_now.dart';
import '../models/location_data.dart';
import '../providers/location_provider.dart';
import '../providers/time_providers.dart';
import '../theme.dart';
import '../widgets/ghuroubi_face.dart';

class ClockScreen extends ConsumerWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(ghuroubiNowProvider);
    final loc = ref.watch(locationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'التوقيت الغروبي',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gold),
          ),
          const SizedBox(height: 20),
          Center(child: GhuroubiFace(clock: g.clock)),
          const SizedBox(height: 16),
          _SunsetCountdown(g.nextSunset),
          const SizedBox(height: 20),
          _solarAndCivil(g),
          const SizedBox(height: 16),
          _dates(g),
          const SizedBox(height: 16),
          _locationCard(loc),
        ],
      ),
    );
  }

  Widget _solarAndCivil(GhuroubiNow g) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _stat(
              'التوقيت الزوالي',
              fmt12FromHm(g.solar.hour, g.solar.minute),
              big: true,
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.muted.withValues(alpha: 0.3)),
          Expanded(
            child: _stat('التوقيت المدني', fmt12(g.now)),
          ),
        ],
      ),
    );
  }

  Widget _dates(GhuroubiNow g) {
    final h = g.hijri;
    final hijriText = toArabicDigits('${h.hDay} ${h.longMonthName} ${h.hYear} هـ');
    final c = g.ghuroubiCivilDate;
    final gregText =
        toArabicDigits('${c.day} ${gregorianMonthAr(c.month)} ${c.year} م');
    return _card(
      child: Column(
        children: [
          Text(weekdayAr(g.now.weekday),
              style: const TextStyle(fontSize: 15, color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(hijriText,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onDark)),
          const SizedBox(height: 4),
          Text(gregText, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _locationCard(LocationData loc) {
    return _card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(loc.isManual ? Icons.edit_location_alt : Icons.my_location,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(loc.isManual ? 'موقع يدوي' : 'موقع GPS',
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ),
          Text(
            toArabicDigits(
                '${loc.latitude.toStringAsFixed(2)}°، ${loc.longitude.toStringAsFixed(2)}° • ${loc.altitude.round()} م'),
            style: const TextStyle(color: AppColors.onDark, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool big = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: big ? 24 : 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onDark)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

/// عدّاد «بقي للغروب» — يراقب نبضة الثانية وحده (widget صغير) فلا يُعيد بناء بقية
/// شاشة الساعة كل ثانية. [nextSunset] يأتي من اللقطة الدقيقية ويتبدّل عند الغروب.
class _SunsetCountdown extends ConsumerWidget {
  final DateTime nextSunset;
  const _SunsetCountdown(this.nextSunset);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(secondTickerProvider);
    final remaining = nextSunset.difference(now);
    return Center(
      child: Text(
        'بقي للغروب القادم: ${formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
        style: const TextStyle(fontSize: 15, color: AppColors.muted),
      ),
    );
  }
}
