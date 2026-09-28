import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'diag_log.dart';

/// تقارير الأعطال: كل خطأ غير ملتقَط يُسجَّل في سجل التشخيص المحلي دائماً، ويُرسَل
/// إلى Firebase Crashlytics متى هُيّئ Firebase (لا يدعم Crashlytics الويب).
class CrashReporter {
  CrashReporter._();

  static bool get _crashlyticsReady => Firebase.apps.isNotEmpty && !kIsWeb;

  /// يُستدعى أول `main` قبل أي شيء آخر.
  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      DiagLog.add('crash', _firstLine(details.exception));
      if (_crashlyticsReady) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      DiagLog.add('crash', _firstLine(error));
      if (_crashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  /// يرسل خطأً تجريبياً غير قاتل (من سجل التشخيص) للتحقق من وصول التقارير إلى
  /// لوحة Firebase. يُعيد false إن لم يكن Crashlytics جاهزاً.
  static Future<bool> sendTestReport() async {
    if (!_crashlyticsReady) return false;
    await FirebaseCrashlytics.instance.recordError(
      StateError('تقرير تجريبي من سجل التشخيص'),
      StackTrace.current,
      reason: 'diagnostics test',
    );
    await FirebaseCrashlytics.instance.sendUnsentReports();
    await DiagLog.add('crash', 'أُرسل تقرير أعطال تجريبي');
    return true;
  }

  static String _firstLine(Object error) => '$error'.split('\n').first;
}
