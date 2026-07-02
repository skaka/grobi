import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import 'firebase_options.dart';
import 'providers/announcements_provider.dart';
import 'screens/main_shell.dart';
import 'services/diag_log.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // تفعيل أسماء الأشهر الهجرية العربية عالمياً.
  HijriCalendar.setLocal('ar');

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

    await NotificationService.init();
    // أذونات FCM + استقبال أمامي (الاشتراك بموضوع الدولة يتم عبر الإعدادات).
    await FcmService.init();
    // وصول Push يحمل إعلان مناسبة (مقدّمة) → إعادة مزامنة لإعادة تقييم المعايرة.
    FcmService.onAnnouncementPush =
        () => container.read(announcementsProvider.notifier).syncNow();
  } catch (e) {
    debugPrint('Services init failed: $e');
    await DiagLog.add('boot', 'فشل تهيئة الخدمات: $e');
  }
  await DiagLog.add('boot', 'إقلاع التطبيق');
  // مزامنة الإعلانات عند الإقلاع (تُظهر تنبيهاً لأي جديد).
  container.read(announcementsProvider.notifier).syncNow();
}

class TimerGrobiApp extends StatelessWidget {
  const TimerGrobiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'التوقيت الغروبي',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}
