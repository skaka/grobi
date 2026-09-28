import 'package:flutter/material.dart';
import 'package:timer_grobi/core/app_language.dart';
import 'package:timer_grobi/l10n/app_localizations.dart';

/// غلاف اختبارات الواجهة: MaterialApp بالترجمات ولغة الواجهة المطلوبة، كما في
/// التطبيق (`TimerGrobiApp`) — يضبط [AppLanguage] لِما يُنسَّق خارج الشجرة.
Widget localizedApp(Widget home, {String language = 'ar'}) {
  AppLanguage.code = language;
  return MaterialApp(
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}
