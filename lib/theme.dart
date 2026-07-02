import 'package:flutter/material.dart';

/// ألوان السمة الغروبية.
class AppColors {
  // ليل
  static const nightTop = Color(0xFF0B1026);
  static const nightBottom = Color(0xFF1B2A4A);
  // نهار (شفق غروبي دافئ)
  static const dayTop = Color(0xFF1E3A5F);
  static const dayBottom = Color(0xFFE08A3C);

  static const gold = Color(0xFFD4A24E);
  static const surface = Color(0xFF141A33);
  static const onDark = Color(0xFFF2E9D8);
  static const muted = Color(0xFF9AA3B8);
}

/// تدرّجا الخلفية (نهار/ليل) ثابتان — يُنشآن مرة واحدة بدل كل إعادة بناء.
const _dayGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.dayTop, AppColors.dayBottom],
);
const _nightGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.nightTop, AppColors.nightBottom],
);

/// تدرّج الخلفية حسب نهار/ليل.
LinearGradient backgroundGradient(bool isDaytime) =>
    isDaytime ? _dayGradient : _nightGradient;

ThemeData buildAppTheme() {
  const seed = AppColors.gold;
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.nightTop,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Cairo',
      bodyColor: AppColors.onDark,
      displayColor: AppColors.onDark,
    ),
  );
}
