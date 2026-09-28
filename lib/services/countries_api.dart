import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/countries.dart';

/// قائمة الدول من الخادم (`/api/v1/countries.php`) مع نسخة محفوظة محلياً، كي تُضاف
/// دولة من اللوحة دون إصدار جديد للتطبيق. القائمة المضمَّنة [kCountries] احتياط أخير.
class CountriesApi {
  static const _kCache = 'countries.cache';

  final String baseUrl;
  const CountriesApi(this.baseUrl);

  /// يجلب القائمة من الخادم. يرمي عند فشل الشبكة أو استجابة غير صالحة أو فارغة.
  Future<List<Country>> fetch() async {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final res = await http
        .get(Uri.parse('$base/api/v1/countries.php'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final list = parseCountries(jsonDecode(res.body));
    if (list.isEmpty) throw Exception('قائمة دول فارغة');
    return list;
  }

  /// النسخة المحفوظة من آخر جلب ناجح (null إن لم توجد أو تلفت).
  static Future<List<Country>?> loadCached() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kCache);
      if (raw == null) return null;
      final list = parseCountries({'countries': jsonDecode(raw)});
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCache(List<Country> countries) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _kCache, jsonEncode([for (final c in countries) c.toJson()]));
  }
}

/// منطق نقيّ (قابل للاختبار): يستخرج الدول الصالحة من استجابة {countries: [...]}
/// ويُسقط المكرَّر والناقص.
List<Country> parseCountries(Object? body) {
  if (body is! Map) return const [];
  final raw = body['countries'];
  if (raw is! List) return const [];
  final seen = <String>{};
  return [
    for (final row in raw.whereType<Map<String, dynamic>>())
      if (Country.fromServer(row) case final c? when seen.add(c.code)) c,
  ];
}
