import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format_utils.dart';
import '../core/ghuroubi_date.dart';
import '../l10n/l10n.dart';
import '../models/ghuroubi_now.dart';
import '../models/location_data.dart';
import '../providers/location_provider.dart';
import '../providers/time_providers.dart';
import '../theme.dart';
import '../widgets/ghuroubi_face.dart';
import '../widgets/location_picker.dart';

class ClockScreen extends ConsumerWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(ghuroubiNowProvider);
    final loc = ref.watch(locationProvider);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gold),
          ),
          if (loc.isFallback) ...[
            const SizedBox(height: 12),
            DefaultLocationBanner(onPick: () => showLocationPicker(context)),
          ],
          const SizedBox(height: 20),
          Center(child: GhuroubiFace(clock: g.clock)),
          const SizedBox(height: 16),
          _SunsetCountdown(g.nextSunset),
          const SizedBox(height: 20),
          _solarAndCivil(l10n, g),
          const SizedBox(height: 16),
          _dates(g),
          const SizedBox(height: 16),
          _locationCard(context, loc),
        ],
      ),
    );
  }

  Widget _solarAndCivil(AppLocalizations l10n, GhuroubiNow g) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _stat(
              l10n.solarTime,
              fmt12FromHm(g.solar.hour, g.solar.minute),
              big: true,
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.muted.withValues(alpha: 0.3)),
          Expanded(
            child: _stat(l10n.civilTime, fmt12(g.now)),
          ),
        ],
      ),
    );
  }

  Widget _dates(GhuroubiNow g) {
    final h = g.hijri;
    final hijriText = formatHijriDate(h.hDay, h.hMonth, h.hYear);
    final gregText = formatGregorianDate(g.ghuroubiCivilDate);
    return _card(
      child: Column(
        children: [
          Text(ghuroubiDayName(g.now, g.today),
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

  Widget _locationCard(BuildContext context, LocationData loc) {
    final IconData icon;
    switch (loc.source) {
      case LocationSource.fallback:
        icon = Icons.location_off;
      case LocationSource.gps:
        icon = Icons.my_location;
      case LocationSource.manual:
        icon = Icons.edit_location_alt;
    }
    return GestureDetector(
      onTap: () => showLocationPicker(context),
      child: _card(
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(locationSourceLabel(loc),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted)),
            ),
            const SizedBox(width: 8),
            Text(
              localDigits('${loc.latitude.toStringAsFixed(2)}°، '
                  '${loc.longitude.toStringAsFixed(2)}°'),
              style: const TextStyle(color: AppColors.onDark, fontSize: 13),
            ),
          ],
        ),
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
        context.l10n.untilNextSunset(
            formatDuration(remaining.isNegative ? Duration.zero : remaining)),
        style: const TextStyle(fontSize: 15, color: AppColors.muted),
      ),
    );
  }
}

/// شريط ظاهر حين تُحسب المواقيت لموقع افتراضي (مكة المكرمة) لأن الموقع لم يُحدَّد:
/// مستخدم في جاكرتا مثلاً كان يرى مواقيت مكة دون أي إشارة.
class DefaultLocationBanner extends StatelessWidget {
  final VoidCallback onPick;
  const DefaultLocationBanner({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.defaultLocationBanner,
              style: const TextStyle(color: AppColors.onDark, fontSize: 13),
            ),
          ),
          TextButton(
              onPressed: onPick, child: Text(context.l10n.setLocationShort)),
        ],
      ),
    );
  }
}
