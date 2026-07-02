import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format_utils.dart';
import '../core/hijri_calibration.dart';
import '../models/islamic_event.dart';
import '../providers/announcements_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/time_providers.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'calendar_screen.dart';
import 'clock_screen.dart';
import 'events_screen.dart';
import 'prayer_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _index = 0;
  final PageController _pageController = PageController();

  /// مفاتيح الاقتراحات التي عُولِجت في هذه الجلسة (تفادي تكرار الحوار/التطبيق).
  final Set<String> _handledThisSession = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  /// إيقاف المؤقّتات عند تصغير التطبيق (توفير بطارية)، واستئنافها عند العودة.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final second = ref.read(secondTickerProvider.notifier);
    final minute = ref.read(minuteTickerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      second.resume();
      minute.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      second.pause();
      minute.pause();
    }
  }

  // تُغلَّف كل صفحة بـ KeepAlivePage للحفاظ على حالتها (شهر التقويم، حالة
  // المزامنة) عند التنقّل بالسحب بين الصفحات في PageView.
  static const _screens = [
    _KeepAlivePage(child: ClockScreen()),
    _KeepAlivePage(child: PrayerScreen()),
    _KeepAlivePage(child: QiblaScreen()),
    _KeepAlivePage(child: CalendarScreen()),
    _KeepAlivePage(child: EventsScreen()),
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  /// يستجيب لاقتراح معايرة التقويم: تطبيق تلقائي أو حوار تأكيد.
  void _onCalibration(CalibrationSuggestion? s) {
    if (s == null || _handledThisSession.contains(s.handledKey)) return;
    _handledThisSession.add(s.handledKey);
    final notifier = ref.read(announcementsProvider.notifier);

    if (ref.read(settingsProvider).autoCalibrate) {
      notifier.applyCalibration(s);
      String adj(int a) => a > 0 ? '+$a' : '$a';
      NotificationService.show(
        911,
        'تصحيح التقويم',
        'صُحّح التاريخ الهجري تلقائياً إلى ${toArabicDigits(adj(s.suggestedAdjust))} '
            '(${s.announcement.type.arabicName}).',
      );
      return;
    }

    // حوار تأكيد (يظهر على أي تبويب).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showCalibrationDialog(s);
    });
  }

  Future<void> _showCalibrationDialog(CalibrationSuggestion s) async {
    String adj(int a) => a > 0 ? '+$a' : '$a';
    var auto = false;
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('ثبت ${s.announcement.type.arabicName}',
              style: const TextStyle(color: AppColors.onDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اضبط تعديل التاريخ الهجري من ${toArabicDigits(adj(s.currentAdjust))} '
                'إلى ${toArabicDigits(adj(s.suggestedAdjust))}؟',
                style: const TextStyle(color: AppColors.onDark),
              ),
              CheckboxListTile(
                value: auto,
                onChanged: (v) => setLocal(() => auto = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.gold,
                dense: true,
                title: const Text('طبّق التصحيحات تلقائياً مستقبلاً',
                    style: TextStyle(color: AppColors.onDark, fontSize: 13)),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('تجاهل')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تطبيق')),
          ],
        ),
      ),
    );
    final notifier = ref.read(announcementsProvider.notifier);
    if (apply == true) {
      notifier.applyCalibration(s, auto: auto);
    } else {
      notifier.dismissCalibration(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    // يُعاد البناء فقط عند تبدّل نهار/ليل (لا كل ثانية).
    final isDaytime = ref.watch(
      ghuroubiNowProvider.select((g) => g.clock.isDaytime),
    );

    ref.listen<CalibrationSuggestion?>(
      pendingCalibrationProvider,
      (_, next) => _onCalibration(next),
    );

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient(isDaytime)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _index = i),
            children: _screens,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.surface.withValues(alpha: 0.92),
          selectedIndex: _index,
          onDestinationSelected: (i) => _pageController.jumpToPage(i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.access_time_outlined),
              selectedIcon: Icon(Icons.access_time_filled),
              label: 'الساعة',
            ),
            NavigationDestination(
              icon: Icon(Icons.mosque_outlined),
              selectedIcon: Icon(Icons.mosque),
              label: 'المواقيت',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'القبلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'التقويم',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'المناسبات',
            ),
          ],
        ),
      ),
    );
  }
}

/// غلاف يُبقي صفحة الـ PageView حيّة عند التنقّل عنها (يحفظ حالتها الداخلية).
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
