import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/countries.dart';
import '../services/announcements_api.dart';
import '../services/countries_api.dart';
import '../services/diag_log.dart';

/// قائمة الدول المعروضة: المضمَّنة فوراً، ثم المحفوظة، ثم الأحدث من الخادم.
/// أي فشل في الشبكة يُبقي آخر قائمة صالحة بصمت.
class CountriesNotifier extends Notifier<List<Country>> {
  @override
  List<Country> build() {
    _load();
    return kCountries;
  }

  Future<void> _load() async {
    final cached = await CountriesApi.loadCached();
    if (cached != null) state = cached;
    try {
      final fresh = await const CountriesApi(kAnnouncementsBaseUrl).fetch();
      state = fresh;
      await CountriesApi.saveCache(fresh);
    } catch (e) {
      await DiagLog.add('countries', 'تعذّر جلب قائمة الدول: $e');
    }
  }
}

final countriesProvider =
    NotifierProvider<CountriesNotifier, List<Country>>(CountriesNotifier.new);
