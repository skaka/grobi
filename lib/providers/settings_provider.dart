import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_language.dart';
import '../models/app_settings.dart';
import '../services/fcm_service.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kMethod = 'settings.method';
  static const _kHijriAdjust = 'settings.hijriAdjust';
  static const _kHorizonHeight = 'settings.horizonHeight';
  // مفتاح قديم: «ارتفاع يدوي» كان يُطبَّق ارتفاعَ مدينة كاملاً فيؤخّر المغرب عن
  // الجداول الرسمية. لا يُرحَّل إلى [_kHorizonHeight] (معنى مختلف) بل يُحذف.
  static const _kLegacyManualAltitude = 'settings.manualAltitude';
  static const _kCountryCode = 'settings.countryCode';
  static const _kLanguage = 'settings.language';
  // مفتاحا ميزة «معايرة التقويم» المحذوفة (حلّ محلّها تثبيت الأشهر من الإعلانات).
  static const _kLegacyAutoCalibrate = 'settings.autoCalibrate';
  static const _kLegacyCalibrated = 'announcements.calibrated';

  late Future<void> _ready;

  /// يكتمل بعد تحميل الإعدادات المحفوظة.
  Future<void> get ready => _ready;

  @override
  AppSettings build() {
    _ready = _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final methodName = p.getString(_kMethod);
    final method = CalculationMethod.values.firstWhere(
      (m) => m.name == methodName,
      orElse: () => CalculationMethod.umm_al_qura,
    );
    state = AppSettings(
      method: method,
      hijriAdjust: p.getInt(_kHijriAdjust) ?? 0,
      horizonHeight: p.getDouble(_kHorizonHeight) ?? 0,
      countryCode: p.getString(_kCountryCode),
      languageCode: p.getString(_kLanguage),
    );
    await p.remove(_kLegacyManualAltitude);
    await p.remove(_kLegacyAutoCalibrate);
    await p.remove(_kLegacyCalibrated);
    // ضمان الاشتراك بموضوع الدولة المحفوظة عند كل إقلاع (آمن وعديم الأثر إن تكرّر).
    FcmService.subscribeToCountry(state.countryCode);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMethod, state.method.name);
    await p.setInt(_kHijriAdjust, state.hijriAdjust);
    await p.setDouble(_kHorizonHeight, state.horizonHeight);
    final country = state.countryCode;
    if (country == null) {
      await p.remove(_kCountryCode);
    } else {
      await p.setString(_kCountryCode, country);
    }
    final language = state.languageCode;
    if (language == null) {
      await p.remove(_kLanguage);
    } else {
      await p.setString(_kLanguage, language);
    }
  }

  void setMethod(CalculationMethod method) {
    state = state.copyWith(method: method);
    _save();
  }

  void setHijriAdjust(int days) {
    state = state.copyWith(hijriAdjust: days.clamp(-2, 2));
    _save();
  }

  /// ارتفاع الراصد فوق الأفق المحيط (متر، 0 = بلا تصحيح). يُحصر في مدى معقول.
  void setHorizonHeight(double meters) {
    state = state.copyWith(horizonHeight: meters.clamp(0, 3000).toDouble());
    _save();
  }

  /// لغة الواجهة: null = لغة الجهاز.
  void setLanguage(String? code) {
    state = code == null
        ? state.copyWith(useDeviceLanguage: true)
        : state.copyWith(languageCode: code);
    _save();
    AppLanguage.applyToPlatform(code);
  }

  void setCountryCode(String? code) {
    final previous = state.countryCode;
    state = state.copyWith(countryCode: code);
    _save();
    // تبديل اشتراك FCM: إلغاء الدولة السابقة والاشتراك بالجديدة.
    FcmService.switchCountry(previous, code);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
