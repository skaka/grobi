import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/islamic_event.dart';

/// عنوان خادم الإعلانات الثابت (PHP).
const String kAnnouncementsBaseUrl = 'https://grobi.misoor.com';

/// عميل واجهة الخادم (PHP) لجلب إعلانات دولة.
class AnnouncementsApi {
  final String baseUrl; // مثل: https://example.com/server

  const AnnouncementsApi(this.baseUrl);

  Future<List<EventAnnouncement>> fetch(String countryCode) async {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$base/api/announcements.php?country=$countryCode');
    final res = await http.get(url).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['announcements'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(EventAnnouncement.fromServer)
        .whereType<EventAnnouncement>()
        .toList();
  }
}
