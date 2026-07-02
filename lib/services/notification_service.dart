import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// تنبيهات محلية (تُستخدم لعرض إعلانات المناسبات سواء من المزامنة أو لاحقاً من FCM).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'islamic_events',
    'المناسبات الإسلامية',
    channelDescription: 'إشعارات دخول رمضان والأعياد والسنة الهجرية',
    importance: Importance.max,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> show(int id, String title, String body) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
