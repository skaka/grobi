import 'package:adhan/adhan.dart';

/// إعدادات التطبيق المحفوظة.
class AppSettings {
  final CalculationMethod method;
  final int hijriAdjust; // تعديل يدوي ±يوم للتاريخ الهجري (احتياطي فوق تثبيت الإعلانات)
  final double horizonHeight; // ارتفاع الراصد فوق الأفق المحيط (متر) — 0 = بلا تصحيح
  final String? countryCode; // دولة الإعلانات (اشتراك/مزامنة)
  final String? languageCode; // لغة الواجهة: null = لغة الجهاز، أو 'ar' / 'en'

  const AppSettings({
    this.method = CalculationMethod.umm_al_qura,
    this.hijriAdjust = 0,
    this.horizonHeight = 0,
    this.countryCode,
    this.languageCode,
  });

  AppSettings copyWith({
    CalculationMethod? method,
    int? hijriAdjust,
    double? horizonHeight,
    String? countryCode,
    String? languageCode,
    bool useDeviceLanguage = false,
  }) {
    return AppSettings(
      method: method ?? this.method,
      hijriAdjust: hijriAdjust ?? this.hijriAdjust,
      horizonHeight: horizonHeight ?? this.horizonHeight,
      countryCode: countryCode ?? this.countryCode,
      languageCode:
          useDeviceLanguage ? null : (languageCode ?? this.languageCode),
    );
  }
}
