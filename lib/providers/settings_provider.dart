import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../services/fcm_service.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kMethod = 'settings.method';
  static const _kHijriAdjust = 'settings.hijriAdjust';
  static const _kManualAltitude = 'settings.manualAltitude';
  static const _kCountryCode = 'settings.countryCode';
  static const _kAutoCalibrate = 'settings.autoCalibrate';

  @override
  AppSettings build() {
    _load();
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
      manualAltitude: p.getDouble(_kManualAltitude),
      countryCode: p.getString(_kCountryCode),
      autoCalibrate: p.getBool(_kAutoCalibrate) ?? false,
    );
    // ضمان الاشتراك بموضوع الدولة المحفوظة عند كل إقلاع (آمن وعديم الأثر إن تكرّر).
    FcmService.subscribeToCountry(state.countryCode);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kMethod, state.method.name);
    await p.setInt(_kHijriAdjust, state.hijriAdjust);
    final alt = state.manualAltitude;
    if (alt == null) {
      await p.remove(_kManualAltitude);
    } else {
      await p.setDouble(_kManualAltitude, alt);
    }
    final country = state.countryCode;
    if (country == null) {
      await p.remove(_kCountryCode);
    } else {
      await p.setString(_kCountryCode, country);
    }
    await p.setBool(_kAutoCalibrate, state.autoCalibrate);
  }

  void setMethod(CalculationMethod method) {
    state = state.copyWith(method: method);
    _save();
  }

  void setHijriAdjust(int days) {
    state = state.copyWith(hijriAdjust: days.clamp(-2, 2));
    _save();
  }

  void setAutoCalibrate(bool value) {
    state = state.copyWith(autoCalibrate: value);
    _save();
  }

  void setManualAltitude(double? altitude) {
    state = state.copyWith(
      manualAltitude: altitude,
      clearManualAltitude: altitude == null,
    );
    _save();
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
