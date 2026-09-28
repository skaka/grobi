import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/core/app_language.dart';
import 'package:timer_grobi/screens/calendar_screen.dart';
import 'package:timer_grobi/screens/clock_screen.dart';
import 'package:timer_grobi/screens/main_shell.dart';

import 'helpers.dart';

void main() {
  tearDown(() => AppLanguage.code = 'ar');

  testWidgets('يبني الهيكل الرئيسي بالتبويبات الخمسة (عربي)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(child: localizedApp(const MainShell())));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('الساعة'), findsOneWidget);
    expect(find.text('المواقيت'), findsOneWidget);
    expect(find.text('التقويم'), findsOneWidget);
    expect(find.text('القبلة'), findsOneWidget);
    expect(find.text('المناسبات'), findsOneWidget);
  });

  testWidgets('الواجهة الإنجليزية: تبويبات وعنوان وأرقام لاتينية', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
        child: localizedApp(const MainShell(), language: 'en')));
    await tester.pump(const Duration(seconds: 1));

    for (final tab in ['Clock', 'Prayers', 'Qibla', 'Calendar', 'Events']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
    expect(find.byType(ClockScreen), findsOneWidget);
    expect(find.text('Ghuroubi Time'), findsOneWidget);
    expect(find.textContaining('Location not set'), findsOneWidget);
    // لا أرقام هندية في الواجهة الإنجليزية.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(RegExp('[٠-٩]').hasMatch(texts), isFalse, reason: texts);
  });

  testWidgets('التقويم بالإنجليزية: أرقام الخلايا لاتينية ورؤوس الأيام إنجليزية',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
        child: localizedApp(const Scaffold(body: CalendarScreen()),
            language: 'en')));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sat'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.textContaining(' AH'), findsWidgets);
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(RegExp('[٠-٩]').hasMatch(texts), isFalse, reason: texts);
  });
}
