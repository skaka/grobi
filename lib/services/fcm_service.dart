import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/islamic_event.dart';
import 'announcements_store.dart';
import 'diag_log.dart';
import 'notification_service.dart';

/// معالج رسائل الخلفية — يجب أن يكون دالة عُليا (top-level) ومعلّمة بـ vm:entry-point
/// كي تجدها Flutter في عزلة (isolate) منفصلة.
///
/// رسائل الخادم تحمل حقل `notification`، فيعرضها أندرويد تلقائياً في شريط
/// الإشعارات عندما يكون التطبيق في الخلفية أو مغلقاً — لذا لا حاجة لعرضها هنا.
/// لكننا نلتقط حقل `data` المنظَّم (إعلان رؤية) ونخزّنه محلياً ليُعرض اقتراح
/// المعايرة عند فتح التطبيق لاحقاً.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await FcmService.ingestAnnouncementData(message.data);
}

/// طبقة FCM: أذونات + استقبال أمامي + الاشتراك بموضوع الدولة.
///
/// كل الدوال آمنة قبل تهيئة Firebase: إن لم يُستدعَ `Firebase.initializeApp`
/// بعد (مثلاً قبل تشغيل `flutterfire configure`) فإنها تعود دون فعل شيء.
class FcmService {
  /// موضوع عام يشترك فيه كل من يحمل التطبيق — للبثّ الجماعي لكل المستخدمين.
  static const String kAllTopic = 'all';

  /// مفتاح دولة المستخدم في SharedPreferences (مطابق لـ SettingsNotifier).
  static const String _kCountryCode = 'settings.countryCode';

  /// خطاف يُستدعى عند وصول Push يحمل إعلان مناسبة في المقدّمة (لإعادة المزامنة/التقييم).
  static void Function()? onAnnouncementPush;

  static bool _initialized = false;

  /// جاهز للاشتراك بالمواضيع: Firebase مُهيّأ والمنصّة تدعم المواضيع
  /// (الويب لا يدعم subscribeToTopic عبر العميل).
  static bool get _topicsReady => Firebase.apps.isNotEmpty && !kIsWeb;

  /// تُستدعى بعد `Firebase.initializeApp` و`NotificationService.init`.
  static Future<void> init() async {
    if (_initialized || Firebase.apps.isEmpty) return;
    final fm = FirebaseMessaging.instance;

    await fm.requestPermission();

    // اشتراك كل مستخدم في الموضوع العام للبثّ الجماعي (آمن وعديم الأثر إن تكرّر).
    if (_topicsReady) {
      await fm.subscribeToTopic(kAllTopic);
    }

    // في المقدمة لا يعرض أندرويد الإشعار تلقائياً، فنعرضه يدوياً عبر التنبيهات المحلية.
    FirebaseMessaging.onMessage.listen((message) async {
      final n = message.notification;
      if (n != null) {
        NotificationService.show(n.hashCode, n.title ?? '', n.body ?? '');
      }
      // التقاط إعلان الرؤية المنظَّم (إن وُجد) ثم إعادة التقييم.
      final ingested = await ingestAnnouncementData(message.data);
      if (ingested) onAnnouncementPush?.call();
    });

    _initialized = true;
  }

  /// يلتقط حقل `data` لإشعار مناسبة: يتحقق من تطابق الدولة، يخزّنه محلياً، ويسجّل.
  /// يُعيد true إذا كان إعلان مناسبة صالحاً (وإلا false — مثل البثّ الحرّ).
  /// آمن للاستدعاء من عزلة الخلفية (يعتمد على SharedPreferences فقط).
  static Future<bool> ingestAnnouncementData(Map<String, dynamic> data) async {
    if (data.isEmpty) return false;
    final ann = EventAnnouncement.fromPushData(data);
    if (ann == null) return false; // ليس إعلان مناسبة

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final myCountry = prefs.getString(_kCountryCode);
    final pushCountry = data['country'] as String?;
    if (myCountry != null && pushCountry != null && myCountry != pushCountry) {
      await DiagLog.add('push', 'تجاهل إعلان دولة مختلفة: $pushCountry');
      return false;
    }

    await AnnouncementsStore().upsert(ann);
    await DiagLog.add('push',
        'استُلم إعلان ${ann.type.id} (${pushCountry ?? '-'}) — ${data['gregorian_date']}');
    return true;
  }

  /// الاشتراك بموضوع الدولة (الرمز = اسم الموضوع، مطابق للخادم).
  static Future<void> subscribeToCountry(String? code) async {
    if (!_topicsReady || code == null || code.isEmpty) return;
    await FirebaseMessaging.instance.subscribeToTopic(code);
  }

  /// إلغاء الاشتراك بموضوع دولة.
  static Future<void> unsubscribeFromCountry(String? code) async {
    if (!_topicsReady || code == null || code.isEmpty) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic(code);
  }

  /// التبديل من دولة قديمة إلى أخرى (يلغي القديمة ويشترك بالجديدة).
  static Future<void> switchCountry(String? oldCode, String? newCode) async {
    if (oldCode == newCode) return;
    await unsubscribeFromCountry(oldCode);
    await subscribeToCountry(newCode);
  }
}
