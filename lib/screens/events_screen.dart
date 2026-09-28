import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format_utils.dart';
import '../l10n/l10n.dart';
import '../models/islamic_event.dart';
import '../providers/announcements_provider.dart';
import '../theme.dart';
import 'diagnostics_screen.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  bool _syncing = false;

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
    final stored = ref.watch(announcementsProvider);

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
            child: Text(context.l10n.eventsTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold)),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.eventsSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 16),
          _syncButton(),
          const SizedBox(height: 16),
          _eventsList(stored),
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
      label: Text(_syncing ? context.l10n.syncing : context.l10n.syncNow),
    );
  }

  Widget _eventsList(AsyncValue<List<EventAnnouncement>> stored) {
    return stored.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(context.l10n.errorWith('$e'),
          style: const TextStyle(color: AppColors.muted)),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(context.l10n.noAnnouncements,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted)),
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
    final dateText = formatGregorianDate(a.gregorianDate, withEra: false);
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
          // التثبيت الصامت (شهر بلا مناسبة مسمّاة) يُعرض بهدوء: صحّح التقويم دون إشعار.
          Text(a.isSilent ? '📅' : '🌙', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(announcementTitle(a),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: a.isSilent ? FontWeight.w500 : FontWeight.w700,
                        color: a.isSilent ? AppColors.muted : AppColors.onDark)),
                Text('$dateText • ${localDigits('${a.hijriYear}')} $hijriEra',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
