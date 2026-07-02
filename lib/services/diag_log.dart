import 'package:shared_preferences/shared_preferences.dart';

/// سجلّ تشخيص بسيط (حلقي) على [SharedPreferences] — يعمل من المقدّمة ومن عزلة
/// الخلفية (FCM). كل مُدخَل سطر: `وقت‹tab›وسم‹tab›رسالة`. يُحتفظ بآخر [maxEntries].
class DiagLog {
  static const _key = 'diag.log';
  static const int maxEntries = 200;

  /// يضيف مُدخَلاً موسوماً بالوقت. آمن: يتجاهل أي خطأ كي لا يُعطّل المسار الأساسي.
  static Future<void> add(String tag, String message) async {
    try {
      final p = await SharedPreferences.getInstance();
      // مهمّة في عزلة الخلفية كي نرى كتابات المقدّمة قبل الإلحاق.
      await p.reload();
      final list = p.getStringList(_key) ?? <String>[];
      final ts = DateTime.now().toIso8601String();
      final safe = message.replaceAll('\t', ' ').replaceAll('\n', ' ');
      list.add('$ts\t$tag\t$safe');
      if (list.length > maxEntries) {
        list.removeRange(0, list.length - maxEntries);
      }
      await p.setStringList(_key, list);
    } catch (_) {/* تجاهل: السجل مساعد لا حرج */}
  }

  /// المُدخَلات بالترتيب الزمني (الأقدم أولاً).
  static Future<List<String>> entries() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return p.getStringList(_key) ?? <String>[];
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
