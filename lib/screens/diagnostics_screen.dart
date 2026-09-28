import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format_utils.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/location_data.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../services/announcements_api.dart';
import '../services/diag_log.dart';
import '../services/crash_reporter.dart';
import '../services/fcm_service.dart';
import '../theme.dart';
import '../widgets/location_picker.dart';

/// شاشة تشخيص مخفية (تُفتح بضغطة مطوّلة في شاشة المناسبات): لقطة الإعدادات
/// الحالية + سجلّ الأحداث (إشعارات/مزامنات/تعديلات تقويم/أخطاء).
class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  late Future<List<String>> _entries;
  bool? _testTopic; // null حتى يُقرأ التفضيل

  @override
  void initState() {
    super.initState();
    _entries = DiagLog.entries();
    FcmService.testTopicEnabled().then((v) {
      if (mounted) setState(() => _testTopic = v);
    });
  }

  Future<void> _sendTestCrash() async {
    final ok = await CrashReporter.sendTestReport();
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'أُرسل — يظهر في لوحة Firebase ▸ Crashlytics خلال دقائق'
            : 'تعذّر: Firebase غير مهيّأ')));
  }

  Future<void> _toggleTestTopic(bool enabled) async {
    final ok = await FcmService.setTestTopic(enabled);
    if (!mounted) return;
    if (ok) {
      setState(() => _testTopic = enabled);
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر: خدمة الإشعارات غير مهيّأة')));
    }
  }

  void _refresh() => setState(() => _entries = DiagLog.entries());

  Future<void> _copy(List<String> lines) async {
    await Clipboard.setData(ClipboardData(text: lines.reversed.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('نُسخ السجل')));
    }
  }

  Future<void> _clear() async {
    await DiagLog.clear();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final loc = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onDark,
        title: const Text('سجلّ التشخيص'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _snapshotCard(settings, loc),
            const SizedBox(height: 12),
            _card(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إشعارات الاختبار',
                            style: TextStyle(color: AppColors.onDark)),
                        SizedBox(height: 2),
                        Text('يستقبل هذا الجهاز «الإرسال التجريبي» من لوحة التحكّم '
                            '(موضوع test) دون أيّ مشترك آخر.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _testTopic ?? false,
                    activeThumbColor: AppColors.gold,
                    onChanged: _testTopic == null ? null : _toggleTestTopic,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _sendTestCrash,
              icon: const Icon(Icons.bug_report_outlined, size: 18),
              label: const Text('إرسال تقرير أعطال تجريبي (Crashlytics)'),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _entries,
              builder: (context, snap) {
                final lines = snap.data ?? const <String>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('السجل (${toArabicDigits('${lines.length}')})',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: lines.isEmpty ? null : () => _copy(lines),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ'),
                        ),
                        TextButton.icon(
                          onPressed: lines.isEmpty ? null : _clear,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('مسح'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (lines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('لا توجد مُدخَلات بعد.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted)),
                      )
                    else
                      for (final line in lines.reversed) _entryTile(line),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _snapshotCard(AppSettings settings, LocationData loc) {
    String adj(int a) => a > 0 ? '+$a' : '$a';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('الإعدادات الحالية',
              style: TextStyle(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _row('طريقة الحساب', calculationMethodName(settings.method)),
          _row('تعديل التاريخ الهجري', toArabicDigits(adj(settings.hijriAdjust))),
          _row('الدولة', settings.countryCode ?? '—'),
          _row('الخادم', kAnnouncementsBaseUrl),
          _row('الموقع', locationSourceLabel(loc)),
          _row('الارتفاع فوق الأفق',
              toArabicDigits('${settings.horizonHeight.round()} م')),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13))),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppColors.onDark, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(String line) {
    final parts = line.split('\t');
    final ts = parts.isNotEmpty ? parts[0] : '';
    final tag = parts.length > 1 ? parts[1] : '';
    final msg = parts.length > 2 ? parts[2] : '';
    final time = ts.length >= 19 ? ts.substring(0, 19).replaceFirst('T', ' ') : ts;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(time,
                  style: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.8),
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 3),
          Text(msg, style: const TextStyle(color: AppColors.onDark, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.onDark.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}
