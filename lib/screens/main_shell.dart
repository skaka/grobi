import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/announcements_provider.dart';
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/time_providers.dart';
import '../providers/ui_providers.dart';
import '../services/fcm_service.dart';
import '../theme.dart';
import '../widgets/location_picker.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _askPermissionsInSequence());
  }

  /// أذونات الإقلاع **بالتتابع**: أندرويد يُسقط كل طلب أذونات متزامن عدا واحداً،
  /// فكان طلب الموقع يضيع بصمت ويبقى المستخدم على موقع مكة الافتراضي.
  /// 1) الموقع أولاً مع شرح السبب (مرة لكل تثبيت؛ بعدها يبقى الشريط التنبيهي).
  /// 2) ثم التنبيهات لمن اختار دولته سابقاً ولم يُسأل بعد.
  Future<void> _askPermissionsInSequence() async {
    final location = ref.read(locationProvider.notifier);
    final settings = ref.read(settingsProvider.notifier);
    if (await location.shouldExplainPermission() && mounted) {
      final choice = await _showLocationRationale();
      await location.markPermissionExplained();
      if (!mounted) return;
      if (choice == _LocationChoice.allow) {
        final message = gpsResultMessage(await location.requestGps());
        if (message != null && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      } else if (choice == _LocationChoice.pickCity) {
        await showLocationPicker(context);
      }
    }
    await settings.ready;
    if (!mounted) return;
    if (ref.read(settingsProvider).countryCode != null) {
      await FcmService.requestNotificationPermissionOnce();
    }
  }

  Future<_LocationChoice?> _showLocationRationale() {
    final l10n = context.l10n;
    return showDialog<_LocationChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.locationRationaleTitle,
            style: const TextStyle(color: AppColors.onDark)),
        content: Text(
          l10n.locationRationaleBody,
          style: const TextStyle(color: AppColors.onDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _LocationChoice.later),
            child: Text(l10n.notNow),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _LocationChoice.pickCity),
            child: Text(l10n.pickCity),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _LocationChoice.allow),
            child: Text(l10n.allow),
          ),
        ],
      ),
    );
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
      // تثبيتات وصلت عبر FCM والتطبيق في الخلفية خُزّنت من عزلة مستقلة.
      ref.read(announcementsProvider.notifier).reloadFromStore();
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

  @override
  Widget build(BuildContext context) {
    // يُعاد البناء فقط عند تبدّل نهار/ليل (لا كل ثانية).
    final isDaytime = ref.watch(
      ghuroubiNowProvider.select((g) => g.clock.isDaytime),
    );
    final l10n = context.l10n;

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
              tooltip: l10n.settingsTooltip,
              icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: PageView(
            controller: _pageController,
            onPageChanged: (i) {
              setState(() => _index = i);
              ref.read(activeTabProvider.notifier).state = i;
            },
            children: _screens,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppColors.surface.withValues(alpha: 0.92),
          selectedIndex: _index,
          onDestinationSelected: (i) => _pageController.jumpToPage(i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.access_time_outlined),
              selectedIcon: const Icon(Icons.access_time_filled),
              label: l10n.tabClock,
            ),
            NavigationDestination(
              icon: const Icon(Icons.mosque_outlined),
              selectedIcon: const Icon(Icons.mosque),
              label: l10n.tabPrayers,
            ),
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: l10n.tabQibla,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: l10n.tabCalendar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications),
              label: l10n.tabEvents,
            ),
          ],
        ),
      ),
    );
  }
}

enum _LocationChoice { allow, pickCity, later }

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
