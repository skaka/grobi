import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/islamic_event.dart';

/// تخزين الإعلانات المؤكّدة محلياً + تتبّع التي نُبّه عنها (لتفادي التكرار).
class AnnouncementsStore {
  static const _kStored = 'announcements.stored';
  static const _kNotified = 'announcements.notified';

  Future<List<EventAnnouncement>> load() async {
    final p = await SharedPreferences.getInstance();
    await p.reload(); // كي ترى المقدّمةُ ما كتبه معالج الخلفية
    final raw = p.getString(_kStored);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).whereType<Map<String, dynamic>>();
    return list
        .map(EventAnnouncement.fromJson)
        .whereType<EventAnnouncement>()
        .toList();
  }

  Future<void> saveAll(List<EventAnnouncement> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kStored,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// يمسح الإعلانات المخزّنة (عند تغيير الدولة: تثبيتات الدولة السابقة لا تخصّ
  /// تقويم الجديدة).
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kStored);
  }

  /// يدمج إعلاناً واحداً (بمفتاحه) — يُستخدم من معالج الخلفية عند وصول Push.
  Future<void> upsert(EventAnnouncement item) async {
    final current = await load();
    final merged = [
      item,
      ...current.where((e) => e.key != item.key),
    ];
    await saveAll(merged);
  }

  /// مفاتيح ما نُبّه عنه. يُعاد التحميل أولاً لأن معالج FCM الخلفي (عزلة مستقلة)
  /// يعلّم الإعلان منبَّهاً لحظة وصوله.
  Future<Set<String>> notifiedKeys() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return (p.getStringList(_kNotified) ?? const []).toSet();
  }

  Future<void> markNotified(Iterable<String> keys) async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    final set = (p.getStringList(_kNotified) ?? const []).toSet()..addAll(keys);
    await p.setStringList(_kNotified, set.toList());
  }
}

/// منطق نقيّ (قابل للاختبار): الإعلانات التي لم يُنبَّه عنها بعد — تشمل التثبيتات
/// الصامتة كي تُعلَّم مع غيرها، والمزامنة لا تعرض منها إلا المسمّاة.
List<EventAnnouncement> newToNotify(
  List<EventAnnouncement> incoming,
  Set<String> notifiedKeys,
) {
  return incoming.where((a) => !notifiedKeys.contains(a.key)).toList();
}
