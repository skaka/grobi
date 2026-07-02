import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:timer_grobi/screens/main_shell.dart';

void main() {
  testWidgets('يبني الهيكل الرئيسي بالتبويبات الثلاثة', (tester) async {
    HijriCalendar.setLocal('ar');
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MainShell(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('الساعة'), findsOneWidget);
    expect(find.text('المواقيت'), findsOneWidget);
    expect(find.text('التقويم'), findsOneWidget);
  });
}
