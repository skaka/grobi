import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// لغة الواجهة الفعلية الحالية ('ar' أو 'en').
///
/// تُضبط من `MaterialApp.builder` عند كل بناء (بعد تحديد لغة الجهاز أو اختيار
/// المستخدم)، ويقرؤها ما لا يملك `BuildContext`: التنسيق (الأرقام وأسماء الأشهر)،
/// ونصوص التنبيهات المحلية، ورسائل المزوّدات.
class AppLanguage {
  AppLanguage._();

  /// اللغات المدعومة — العربية أولاً (الاحتياط لأي لغة جهاز أخرى).
  static const List<String> supported = ['ar', 'en'];

  static String code = 'ar';

  static bool get isArabic => code == 'ar';

  /// لغة الواجهة لإعداد المستخدم [preferred] (null = لغة الجهاز) ولغة الجهاز
  /// [deviceLanguage]: الإنجليزية لجهاز إنجليزي، والعربية لما عداه.
  static String resolve(String? preferred, String? deviceLanguage) {
    if (preferred != null && supported.contains(preferred)) return preferred;
    return deviceLanguage == 'en' ? 'en' : 'ar';
  }

  static const MethodChannel _channel = MethodChannel('com.misoor.grobi/locale');

  /// يضبط لغة التطبيق لدى النظام ([code] أو null = لغة الجهاز) — أندرويد 13+،
  /// كي تُترجَم إشعارات الخلفية التي يعرضها النظام بنفس لغة الواجهة. يتجاهل
  /// بصمت المنصّات التي لا تدعم ذلك.
  static Future<void> applyToPlatform(String? code) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>('setAppLanguage', {'code': code});
    } on MissingPluginException {
      // اختبارات/منصّة بلا القناة.
    } on PlatformException {
      // لا شيء: الواجهة نفسها تتبع الاختيار على أيّ حال.
    }
  }
}
