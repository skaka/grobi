import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/countries.dart';
import '../core/format_utils.dart';
import '../core/prayer_service.dart';
import '../l10n/l10n.dart';
import '../models/location_data.dart';
import '../providers/announcements_provider.dart';
import '../providers/countries_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/time_providers.dart';
import '../services/fcm_service.dart';
import '../theme.dart';
import '../widgets/location_picker.dart';
import 'about_screen.dart';

/// صفحة الإعدادات الموحّدة — تجمع كل ضوابط المواقيت والمناسبات في مكان واحد.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDaytime =
        ref.watch(ghuroubiNowProvider.select((g) => g.clock.isDaytime));
    final settings = ref.watch(settingsProvider);
    final loc = ref.watch(locationProvider);
    final anchorsActive = ref.watch(hijriAdjustmentsProvider).isNotEmpty;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient(isDaytime)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppColors.onDark),
          title: Text(l10n.settingsTitle,
              style: const TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _languagePicker(l10n, ref, settings.languageCode),
                const SizedBox(height: 20),
                _sectionTitle(l10n.sectionLocation),
                _locationTile(context, loc),
                const SizedBox(height: 20),
                _sectionTitle(l10n.sectionPrayerTimes),
                _methodPicker(l10n, ref, settings.method),
                const SizedBox(height: 10),
                _hijriAdjust(l10n, ref, settings.hijriAdjust, anchorsActive),
                const SizedBox(height: 20),
                _sectionTitle(l10n.sectionEvents),
                _countryPicker(l10n, ref, settings.countryCode),
                const SizedBox(height: 20),
                _sectionTitle(l10n.sectionAdvanced),
                _horizonControl(context, ref, settings.horizonHeight),
                const SizedBox(height: 20),
                _sectionTitle(l10n.sectionInfo),
                _aboutTile(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w700)),
    );
  }

  /// لغة الواجهة: لغة الجهاز (افتراضياً) أو العربية أو الإنجليزية. أسماء اللغتين
  /// تُكتب بلغتيهما (عُرف شائع كي يجدها من لا يقرأ اللغة الحالية).
  Widget _languagePicker(
      AppLocalizations l10n, WidgetRef ref, String? languageCode) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.translate, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(l10n.language, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          DropdownButton<String>(
            value: languageCode ?? '',
            dropdownColor: AppColors.surface,
            underline: const SizedBox.shrink(),
            style:
                const TextStyle(color: AppColors.onDark, fontFamily: 'Cairo'),
            items: [
              DropdownMenuItem(value: '', child: Text(l10n.languageDevice)),
              const DropdownMenuItem(value: 'ar', child: Text('العربية')),
              const DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (code) => ref
                .read(settingsProvider.notifier)
                .setLanguage(code == null || code.isEmpty ? null : code),
          ),
        ],
      ),
    );
  }

  Widget _methodPicker(
      AppLocalizations l10n, WidgetRef ref, CalculationMethod current) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(l10n.calculationMethod,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<CalculationMethod>(
              isExpanded: true,
              value: current,
              dropdownColor: AppColors.surface,
              underline: const SizedBox.shrink(),
              style:
                  const TextStyle(color: AppColors.onDark, fontFamily: 'Cairo'),
              // النص المعروض للاختيار الحالي يُختصر بنقاط إن طال (دون قائمة الاختيار).
              selectedItemBuilder: (context) => [
                for (final m in supportedMethods)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      calculationMethodName(m),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              items: [
                for (final m in supportedMethods)
                  DropdownMenuItem(
                      value: m, child: Text(calculationMethodName(m))),
              ],
              onChanged: (m) {
                if (m != null) ref.read(settingsProvider.notifier).setMethod(m);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationTile(BuildContext context, LocationData loc) {
    return _card(
      child: InkWell(
        onTap: () => showLocationPicker(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(loc.isFallback ? Icons.location_off : Icons.place_outlined,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locationSourceLabel(loc),
                        style: const TextStyle(color: AppColors.onDark)),
                    Text(
                        localDigits('${loc.latitude.toStringAsFixed(3)}°، '
                            '${loc.longitude.toStringAsFixed(3)}°'),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Text(context.l10n.change,
                  style: const TextStyle(color: AppColors.gold)),
              // chevron_right يُعكَس تلقائياً في RTL فيشير «للأمام» في اللغتين.
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  /// التعديل اليدوي (±يوم) احتياطي: يُضاف **فوق** تثبيتات إعلانات الدولة، فإن
  /// كانت التثبيتات فعّالة وهو غير صفر فالتصحيح مزدوج — ننبّه ونعرض التصفير.
  Widget _hijriAdjust(
      AppLocalizations l10n, WidgetRef ref, int adjust, bool anchorsActive) {
    final notifier = ref.read(settingsProvider.notifier);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.manualHijriAdjust,
                    style: const TextStyle(color: AppColors.muted)),
              ),
              IconButton(
                onPressed: () => notifier.setHijriAdjust(adjust - 1),
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.onDark),
              ),
              Text(localDigits(adjust > 0 ? '+$adjust' : '$adjust'),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onDark)),
              IconButton(
                onPressed: () => notifier.setHijriAdjust(adjust + 1),
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.onDark),
              ),
            ],
          ),
          if (anchorsActive && adjust != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l10n.doubleCorrectionWarning,
                        style: const TextStyle(
                            color: AppColors.gold, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => notifier.setHijriAdjust(0),
                    child: Text(l10n.reset),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.manualAdjustHint,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// ارتفاع الراصد **فوق الأفق المحيط** — لا ارتفاع المدينة. معطّل افتراضياً كي
  /// تطابق المواقيت تقويم أم القرى الرسمي.
  Widget _horizonControl(BuildContext context, WidgetRef ref, double height) {
    final l10n = context.l10n;
    return _card(
      child: Row(
        children: [
          const Icon(Icons.terrain_outlined, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.horizonTitle,
                    style:
                        const TextStyle(color: AppColors.onDark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(l10n.horizonDescription,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
              height > 0
                  ? l10n.meters(localDigits('${height.round()}'))
                  : l10n.off,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onDark)),
          IconButton(
            onPressed: () => _editHorizon(context, ref, height),
            icon: const Icon(Icons.edit, color: AppColors.gold, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _editHorizon(
      BuildContext context, WidgetRef ref, double current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
        text: current > 0 ? current.round().toString() : '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.horizonDialogTitle,
            style: const TextStyle(color: AppColors.onDark, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.onDark),
          decoration: InputDecoration(hintText: l10n.horizonDialogHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0.0),
            child: Text(l10n.turnOff),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, parseLocalizedDouble(controller.text)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isNaN) return;
    ref.read(settingsProvider.notifier).setHorizonHeight(result);
  }

  Widget _countryPicker(
      AppLocalizations l10n, WidgetRef ref, String? countryCode) {
    final countries = ref.watch(countriesProvider);
    // دولة محفوظة لم تعد في قائمة الخادم تبقى ظاهرة (DropdownButton يشترط وجودها).
    final items = [
      ...countries,
      if (countryCode != null && !countries.any((c) => c.code == countryCode))
        Country(countryCode, countryName(countryCode) ?? countryCode),
    ];
    return _card(
      child: Row(
        children: [
          const Icon(Icons.public, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(l10n.country, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          DropdownButton<String>(
            value: countryCode,
            hint: Text(l10n.choose,
                style: const TextStyle(color: AppColors.muted)),
            dropdownColor: AppColors.surface,
            underline: const SizedBox.shrink(),
            style:
                const TextStyle(color: AppColors.onDark, fontFamily: 'Cairo'),
            items: [
              for (final c in items)
                DropdownMenuItem(value: c.code, child: Text(c.name)),
            ],
            onChanged: (code) => _onCountryChanged(ref, countryCode, code),
          ),
        ],
      ),
    );
  }

  /// اختيار الدولة هو لحظة طلب إذن التنبيهات (حين يصير لها معنى)، ثم تُستبدل
  /// تثبيتات الدولة السابقة بإعلانات الجديدة.
  Future<void> _onCountryChanged(
      WidgetRef ref, String? previous, String? code) async {
    if (code == null || code == previous) return;
    // يُلتقط قبل الانتظار: قد تُغلق الصفحة أثناء حوار الإذن.
    final announcements = ref.read(announcementsProvider.notifier);
    ref.read(settingsProvider.notifier).setCountryCode(code);
    await FcmService.requestNotificationPermission();
    await announcements.switchCountry();
  }

  Widget _aboutTile(BuildContext context) {
    return _card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Text(context.l10n.aboutApp,
                  style: const TextStyle(color: AppColors.muted)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}
