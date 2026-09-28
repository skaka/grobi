import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../models/islamic_event.dart';
import 'announcements_store.dart';
import 'diag_log.dart';
import 'notification_service.dart';

/// معالج رسائل الخلفية — يجب أن يكون دالة عُليا (top-level) ومعلّمة بـ vm:entry-point
/// كي تجدها Flutter في عزلة (isolate) منفصلة.
///
/// رسائل المناسبات المسمّاة تحمل حقل `notification`، فيعرضها النظام تلقائياً حين
/// يكون التطبيق في الخلفية أو مغلقاً؛ ورسائل التثبيت الصامت بيانات فقط. في الحالتين
/// نلتقط حقل `data` المنظَّم ونخزّنه كي يصحّح التقويم عند فتح التطبيق.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await FcmService.ingestAnnouncementData(message.data);
}

/// طبقة FCM: استقبال أمامي + الاشتراك بموضوع الدولة.
///
/// كل الدوال آمنة قبل تهيئة Firebase: إن لم يُستدعَ `Firebase.initializeApp`
/// بعد (مثلاً قبل تشغيل `flutterfire configure`) فإنها تعود دون فعل شيء.
class FcmService {
  /// موضوع عام يشترك فيه كل من يحمل التطبيق — للبثّ الجماعي لكل المستخدمين.
  static const String kAllTopic = 'all';

  /// مفتاح دولة المستخدم في SharedPreferences (مطابق لـ SettingsNotifier).
  static const String _kCountryCode = 'settings.countryCode';

  /// هل طُلب إذن التنبيهات من قبل (كي لا يُلحّ التطبيق عند كل إقلاع).
  static const String _kPermissionAsked = 'notifications.permissionAsked';

  /// موضوع التجربة (مطابق لـ FCM_TEST_TOPIC في الخادم) وتفضيل الاشتراك فيه.
  static const String kTestTopic = 'test';
  static const String _kTestTopic = 'fcm.testTopic';

  /// خطاف يُستدعى عند وصول Push يحمل إعلان مناسبة في المقدّمة (لإعادة المزامنة).
  static void Function()? onAnnouncementPush;

  static bool _initialized = false;

  /// جاهز للاشتراك بالمواضيع: Firebase مُهيّأ والمنصّة تدعم المواضيع
  /// (الويب لا يدعم subscribeToTopic عبر العميل).
  static bool get _topicsReady => Firebase.apps.isNotEmpty && !kIsWeb;

  /// تُستدعى بعد `Firebase.initializeApp` و`NotificationService.init`. لا تطلب إذن
  /// التنبيهات (انظر [requestNotificationPermission]).
  static Future<void> init() async {
    if (_initialized || Firebase.apps.isEmpty) return;
    final fm = FirebaseMessaging.instance;

    // اشتراك كل مستخدم في الموضوع العام للبثّ الجماعي (آمن وعديم الأثر إن تكرّر).
    if (_topicsReady) {
      await fm.subscribeToTopic(kAllTopic);
    }

    // في المقدمة لا يعرض النظام الإشعار تلقائياً، فنعرضه يدوياً عبر التنبيهات المحلية.
    FirebaseMessaging.onMessage.listen((message) async {
      // الالتقاط أولاً: يعلّم الإعلان منبَّهاً قبل أن تراه المزامنة التالية.
      final ann = await ingestAnnouncementData(message.data);
      final n = message.notification;
      if (n != null) {
        // معرّف ثابت للإعلان: تكرار نفس الإعلان يستبدل التنبيه بدل أن يتراكم.
        final id = NotificationService.idFor(
            ann?.key ?? message.messageId ?? '${n.title}|${n.body}');
        // نصّ المناسبة المسمّاة بلغة الواجهة (نصّ الخادم عربي)؛ والبثّ الحرّ كما كُتب.
        final type = ann?.type;
        await NotificationService.show(
          id,
          type != null ? eventName(type) : n.title ?? '',
          type != null ? eventNotificationBody(type) : n.body ?? '',
        );
      }
      if (ann != null) onAnnouncementPush?.call();
    });

    _initialized = true;
  }

  /// يطلب إذن التنبيهات — عند اختيار الدولة (حين يصير للتنبيهات معنى). على iOS
  /// يُطلب عبر FCM أيضاً كي تُسجَّل رسائل APNs.
  static Future<void> requestNotificationPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPermissionAsked, true);
      await NotificationService.requestPermission();
      if (Firebase.apps.isNotEmpty &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.requestPermission();
      }
    } catch (e) {
      await DiagLog.add('boot', 'تعذّر طلب إذن التنبيهات: $e');
    }
  }

  /// مرة واحدة لكل تثبيت: لمن اختار دولته في نسخة سابقة كانت تطلب الإذن عند الإقلاع
  /// (وربما أسقطه أندرويد لتزاحم الطلبات). القادم الجديد يُسأل عند اختيار الدولة.
  static Future<void> requestNotificationPermissionOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kPermissionAsked) ?? false) return;
    } catch (_) {
      return;
    }
    await requestNotificationPermission();
  }

  /// هل هذا الجهاز مشترك في موضوع التجربة؟
  static Future<bool> testTopicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTestTopic) ?? false;
  }

  /// يشترك الجهاز في موضوع التجربة أو يلغيه — ليستقبل «الإرسال التجريبي» من اللوحة
  /// وحده دون أيّ مشترك حقيقي. يُعيد false إن تعذّر (Firebase غير مهيّأ).
  static Future<bool> setTestTopic(bool enabled) async {
    if (!_topicsReady) return false;
    if (enabled) {
      await FirebaseMessaging.instance.subscribeToTopic(kTestTopic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(kTestTopic);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTestTopic, enabled);
    await DiagLog.add('push', enabled ? 'اشتراك في موضوع الاختبار' : 'إلغاء موضوع الاختبار');
    return true;
  }

  /// يلتقط حقل `data` لإعلان شهر (مسمّى أو صامت): يتحقق من تطابق الدولة، يخزّنه
  /// محلياً، ويعلّمه منبَّهاً فوراً — فالنظام عرضه (خلفية)، أو نعرضه نحن (مقدّمة)،
  /// أو أُرسل صامتاً عمداً؛ وفي كل الأحوال لا تُعيد المزامنة التالية التنبيه به.
  /// يُعيد الإعلان، أو null لغير الإعلانات (مثل البثّ الحرّ) أو لدولة أخرى.
  /// آمن للاستدعاء من عزلة الخلفية (يعتمد على SharedPreferences فقط).
  static Future<EventAnnouncement?> ingestAnnouncementData(
      Map<String, dynamic> data) async {
    if (data.isEmpty) return null;
    final ann = EventAnnouncement.fromPushData(data);
    if (ann == null) return null; // ليس إعلان شهر

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final myCountry = prefs.getString(_kCountryCode);
    final pushCountry = data['country'] as String?;
    if (myCountry != null && pushCountry != null && myCountry != pushCountry) {
      await DiagLog.add('push', 'تجاهل إعلان دولة مختلفة: $pushCountry');
      return null;
    }

    // رسالة تجريبية (data.test=1) تمرّ بالمسار نفسه لتختبره، لكن لا تُعلَّم منبَّهاً
    // كي لا تُسكت إعلاناً حقيقياً بالمفتاح نفسه لاحقاً؛ والمزامنة التالية تستبدل
    // المخزَّن بقائمة الخادم فيزول أثرها من التقويم.
    final isTest = data['test'] == '1';
    final store = AnnouncementsStore();
    await store.upsert(ann);
    if (!isTest) await store.markNotified([ann.key]);
    await DiagLog.add(
        'push',
        '${isTest ? '🧪 تجربة: ' : ''}'
            'استُلم ${ann.isSilent ? 'تثبيت صامت للشهر ${ann.hijriMonth}' : 'إعلان ${ann.type!.id}'} '
            '(${pushCountry ?? '-'}) — ${data['gregorian_date']}');
    return ann;
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
