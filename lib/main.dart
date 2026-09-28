import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_language.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'providers/announcements_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_shell.dart';
import 'services/crash_reporter.dart';
import 'services/diag_log.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // أي خطأ غير ملتقَط من الآن: سجل التشخيص، ثم Crashlytics بعد تهيئة Firebase.
  CrashReporter.install();

  final container = ProviderContainer();

  // عرض الواجهة فوراً — لا تهيئة شبكية/ثقيلة قبل أول إطار.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TimerGrobiApp(),
    ),
  );

  // كل التهيئة الثقيلة (Firebase + الإشعارات + FCM + مزامنة الإعلانات) تجري
  // بعد عرض الواجهة كي لا تُبطئ الإقلاع أو تُعلّقه.
  _initServicesInBackground(container);
}

/// تهيئة الخدمات دون عرقلة الإطار الأول.
Future<void> _initServicesInBackground(ProviderContainer container) async {
  try {
    // تهيئة Firebase + معالج رسائل الخلفية (يجب تسجيله قبل أي استقبال).
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    // لا طلب أذونات هنا: الموقع يُطلب أولاً من MainShell، والتنبيهات عند اختيار
    // الدولة — كي لا تتزاحم الطلبات فيُسقطها أندرويد.
    await NotificationService.init();
    // استقبال أمامي (الاشتراك بموضوع الدولة يتم عبر الإعدادات).
    await FcmService.init();
    // وصول Push يحمل إعلان شهر (مقدّمة): التقويم يتصحّح فوراً من المخزَّن، ثم
    // تُعاد المزامنة مع الخادم.
    FcmService.onAnnouncementPush = () {
      final notifier = container.read(announcementsProvider.notifier);
      notifier.reloadFromStore().then((_) => notifier.syncNow());
    };
  } catch (e) {
    debugPrint('Services init failed: $e');
    await DiagLog.add('boot', 'فشل تهيئة الخدمات: $e');
  }
  await DiagLog.add('boot', 'إقلاع التطبيق');
  // مزامنة الإعلانات عند الإقلاع (تُظهر تنبيهاً لأي جديد).
  container.read(announcementsProvider.notifier).syncNow();
}

class TimerGrobiApp extends ConsumerWidget {
  const TimerGrobiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = ref.watch(settingsProvider.select((s) => s.languageCode));
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // اختيار المستخدم، وإلا لغة الجهاز: الإنجليزية لجهاز إنجليزي والعربية لغيره.
      locale: preferred == null ? null : Locale(preferred),
      localeResolutionCallback: (device, _) =>
          Locale(AppLanguage.resolve(null, device?.languageCode)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // لغة الواجهة الفعلية لما لا يملك BuildContext (التنسيق، التنبيهات المحلية).
      builder: (context, child) {
        final language = Localizations.localeOf(context).languageCode;
        if (AppLanguage.code != language) {
          AppLanguage.code = language;
          NotificationService.refreshChannel().ignore();
        }
        return child!;
      },
      home: const MainShell(),
    );
  }
}
