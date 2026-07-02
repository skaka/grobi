import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/countries.dart';
import '../core/format_utils.dart';
import '../core/prayer_service.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/time_providers.dart';
import '../theme.dart';
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

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient(isDaytime)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: AppColors.onDark),
          title: const Text('الإعدادات',
              style: TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('المواقيت'),
                _methodPicker(ref, settings.method),
                const SizedBox(height: 10),
                _hijriAdjust(ref, settings.hijriAdjust),
                const SizedBox(height: 10),
                _altitudeControl(
                    context, ref, settings.manualAltitude, loc.altitude),
                const SizedBox(height: 20),
                _sectionTitle('المناسبات'),
                _countryPicker(ref, settings.countryCode),
                const SizedBox(height: 10),
                _autoCalibrate(ref, settings.autoCalibrate),
                const SizedBox(height: 20),
                _sectionTitle('معلومات'),
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

  Widget _methodPicker(WidgetRef ref, CalculationMethod current) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          const Text('طريقة الحساب', style: TextStyle(color: AppColors.muted)),
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
                      calculationMethodArabicName(m),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              items: [
                for (final m in supportedMethods)
                  DropdownMenuItem(
                      value: m, child: Text(calculationMethodArabicName(m))),
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

  Widget _hijriAdjust(WidgetRef ref, int adjust) {
    final notifier = ref.read(settingsProvider.notifier);
    return _card(
      child: Row(
        children: [
          const Icon(Icons.event_outlined, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          const Text('تعديل التاريخ الهجري',
              style: TextStyle(color: AppColors.muted)),
          const Spacer(),
          IconButton(
            onPressed: () => notifier.setHijriAdjust(adjust - 1),
            icon:
                const Icon(Icons.remove_circle_outline, color: AppColors.onDark),
          ),
          Text(toArabicDigits(adjust > 0 ? '+$adjust' : '$adjust'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onDark)),
          IconButton(
            onPressed: () => notifier.setHijriAdjust(adjust + 1),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.onDark),
          ),
        ],
      ),
    );
  }

  Widget _altitudeControl(
      BuildContext context, WidgetRef ref, double? manual, double gpsAltitude) {
    final effective = manual ?? gpsAltitude;
    return _card(
      child: Row(
        children: [
          const Icon(Icons.terrain_outlined, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(manual != null ? 'الارتفاع (يدوي)' : 'الارتفاع (GPS)',
              style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(toArabicDigits('${effective.round()} م'),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onDark)),
          IconButton(
            onPressed: () => _editAltitude(context, ref, effective),
            icon: const Icon(Icons.edit, color: AppColors.gold, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _editAltitude(
      BuildContext context, WidgetRef ref, double current) async {
    final controller = TextEditingController(text: current.round().toString());
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('الارتفاع عن سطح البحر (متر)',
            style: TextStyle(color: AppColors.onDark, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.onDark),
          decoration: const InputDecoration(hintText: 'مثال: 760'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.nan), // إشارة المسح
            child: const Text('استخدام GPS'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final notifier = ref.read(settingsProvider.notifier);
    if (result.isNaN) {
      notifier.setManualAltitude(null); // العودة إلى GPS
    } else {
      notifier.setManualAltitude(result);
    }
  }

  Widget _countryPicker(WidgetRef ref, String? countryCode) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.public, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          const Text('الدولة', style: TextStyle(color: AppColors.muted)),
          const Spacer(),
          DropdownButton<String>(
            value: countryCode,
            hint: const Text('اختر', style: TextStyle(color: AppColors.muted)),
            dropdownColor: AppColors.surface,
            underline: const SizedBox.shrink(),
            style:
                const TextStyle(color: AppColors.onDark, fontFamily: 'Cairo'),
            items: [
              for (final c in kCountries)
                DropdownMenuItem(value: c.code, child: Text(c.nameAr)),
            ],
            onChanged: (code) =>
                ref.read(settingsProvider.notifier).setCountryCode(code),
          ),
        ],
      ),
    );
  }

  Widget _autoCalibrate(WidgetRef ref, bool value) {
    return _card(
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تصحيح التقويم تلقائياً',
                    style: TextStyle(color: AppColors.onDark, fontSize: 14)),
                SizedBox(height: 2),
                Text('طبّق تعديل التاريخ من الإشعارات بلا سؤال',
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.gold,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoCalibrate(v),
          ),
        ],
      ),
    );
  }

  Widget _aboutTile(BuildContext context) {
    return _card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        ),
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gold, size: 20),
              SizedBox(width: 10),
              Text('عن التطبيق', style: TextStyle(color: AppColors.muted)),
              Spacer(),
              Icon(Icons.chevron_left, color: AppColors.muted),
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
