import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/l10n.dart';

/// تنبيهات محلية (تُستخدم لعرض إعلانات المناسبات سواء من المزامنة أو من FCM).
///
/// التهيئة **لا تطلب إذناً**: الطلب يجري عبر [requestPermission] حين يصير للتنبيهات
/// معنى (اختيار الدولة)، كي لا يتزاحم مع طلب إذن الموقع عند الإقلاع.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// قناة المناسبات — نفس المعرّف مُعلَن في AndroidManifest قناةً افتراضيةً لـ FCM،
  /// كي لا تسقط رسائل الخلفية في قناة «متفرقات».
  static const String channelId = 'islamic_events';

  // اسم القناة ووصفها بلغة الواجهة (يظهران في إعدادات إشعارات النظام، ويُحدَّثان
  // عند إنشائها مجدداً بعد تغيير اللغة).
  static AndroidNotificationChannel get _channel => AndroidNotificationChannel(
        channelId,
        tr.channelName,
        description: tr.channelDescription,
        importance: Importance.max,
      );

  static AndroidNotificationDetails get _androidDetails =>
      AndroidNotificationDetails(
        channelId,
        tr.channelName,
        channelDescription: tr.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_grobi',
        color: const Color(0xFFD4A24E),
      );

  static Future<void> init() async {
    if (_initialized) return;
    // أيقونة شريط الحالة أحادية اللون (الملوّنة تظهر مربعاً أبيض).
    const android = AndroidInitializationSettings('ic_stat_grobi');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    // إنشاء القناة عند الإقلاع (لا عند أول تنبيه محلي) كي تجدها رسائل FCM الخلفية.
    await refreshChannel();

    _initialized = true;
  }

  /// ينشئ قناة المناسبات أو يحدّث اسمها بلغة الواجهة الحالية.
  static Future<void> refreshChannel() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// يطلب إذن التنبيهات (أندرويد 13+ / iOS). آمن إن سبق منحه أو رفضه.
  static Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> show(int id, String title, String body) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: _androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// معرّف تنبيه ثابت لمفتاح نصّي (FNV-1a 31 بت): نفس الإعلان يُنتج نفس المعرّف
  /// في أي عزلة وأي تشغيل، فيستبدل التكرارُ التنبيهَ السابق بدل أن يتراكم.
  static int idFor(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
