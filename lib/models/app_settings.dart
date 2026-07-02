import 'package:adhan/adhan.dart';

/// إعدادات التطبيق المحفوظة.
class AppSettings {
  final CalculationMethod method;
  final int hijriAdjust; // تعديل يدوي ±يوم للتاريخ الهجري
  final double? manualAltitude; // ارتفاع يدوي يتجاوز ارتفاع GPS (متر)
  final String? countryCode; // دولة الإعلانات (اشتراك/مزامنة)
  final bool autoCalibrate; // تطبيق تصحيح التقويم من الإشعارات تلقائياً بلا سؤال

  const AppSettings({
    this.method = CalculationMethod.umm_al_qura,
    this.hijriAdjust = 0,
    this.manualAltitude,
    this.countryCode,
    this.autoCalibrate = false,
  });

  AppSettings copyWith({
    CalculationMethod? method,
    int? hijriAdjust,
    double? manualAltitude,
    bool clearManualAltitude = false,
    String? countryCode,
    bool? autoCalibrate,
  }) {
    return AppSettings(
      method: method ?? this.method,
      hijriAdjust: hijriAdjust ?? this.hijriAdjust,
      manualAltitude:
          clearManualAltitude ? null : (manualAltitude ?? this.manualAltitude),
      countryCode: countryCode ?? this.countryCode,
      autoCalibrate: autoCalibrate ?? this.autoCalibrate,
    );
  }
}
