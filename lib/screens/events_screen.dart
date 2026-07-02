import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/countries.dart';
import '../core/format_utils.dart';
import '../core/hijri_calibration.dart';
import '../models/islamic_event.dart';
import '../providers/announcements_provider.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import 'diagnostics_screen.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _syncing = false;
  bool _calibrateAutoChecked = false; // مربع «طبّق تلقائياً مستقبلاً»

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final result = await ref.read(announcementsProvider.notifier).syncNow();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final stored = ref.watch(announcementsProvider);
    final pending = ref.watch(pendingCalibrationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ضغطة مطوّلة على العنوان تفتح سجلّ التشخيص المخفي.
          GestureDetector(
            onLongPress: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
            ),
            child: const Text('المناسبات والإعلانات',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold)),
          ),
          const SizedBox(height: 8),
          const Text('إعلانات دخول رمضان والأعياد والسنة الهجرية حسب دولتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 16),
          if (pending != null && !settings.autoCalibrate) ...[
            _calibrationCard(pending),
            const SizedBox(height: 16),
          ],
          _syncButton(),
          const SizedBox(height: 16),
          _eventsList(stored),
        ],
      ),
    );
  }

  Widget _calibrationCard(CalibrationSuggestion s) {
    String adj(int a) => a > 0 ? '+$a' : '$a';
    final name = countryNameAr(ref.read(settingsProvider).countryCode);
    final country = name == null ? '' : ' حسب $name';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text('ثبت ${s.announcement.type.arabicName}$country',
                    style: const TextStyle(
                        color: AppColors.onDark, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'اضبط تعديل التاريخ الهجري من '
            '${toArabicDigits(adj(s.currentAdjust))} إلى '
            '${toArabicDigits(adj(s.suggestedAdjust))}؟',
            style: const TextStyle(color: AppColors.onDark, fontSize: 14),
          ),
          Row(
            children: [
              Checkbox(
                value: _calibrateAutoChecked,
                activeColor: AppColors.gold,
                onChanged: (v) =>
                    setState(() => _calibrateAutoChecked = v ?? false),
              ),
              const Expanded(
                child: Text('طبّق التصحيحات تلقائياً مستقبلاً',
                    style: TextStyle(color: AppColors.onDark, fontSize: 13)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ref.read(announcementsProvider.notifier).applyCalibration(s,
                        auto: _calibrateAutoChecked);
                  },
                  child: const Text('تطبيق'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(announcementsProvider.notifier)
                      .dismissCalibration(s),
                  child: const Text('تجاهل'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _syncButton() {
    return FilledButton.icon(
      onPressed: _syncing ? null : _sync,
      icon: _syncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.sync),
      label: Text(_syncing ? 'جارٍ المزامنة…' : 'مزامنة الإعلانات الآن'),
    );
  }

  Widget _eventsList(AsyncValue<List<EventAnnouncement>> stored) {
    return stored.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: AppColors.muted)),
      data: (list) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('لا توجد إعلانات بعد — اختر الدولة من الإعدادات ثم زامِن.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          );
        }
        final sorted = [...list]
          ..sort((a, b) => b.gregorianDate.compareTo(a.gregorianDate));
        return Column(
          children: [for (final a in sorted) _eventTile(a)],
        );
      },
    );
  }

  Widget _eventTile(EventAnnouncement a) {
    final d = a.gregorianDate;
    final dateText =
        toArabicDigits('${d.day} ${gregorianMonthAr(d.month)} ${d.year}');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.type.arabicName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onDark)),
                Text('$dateText • ${toArabicDigits('${a.hijriYear}')} هـ',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
