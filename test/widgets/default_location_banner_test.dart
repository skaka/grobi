import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/models/location_data.dart';
import 'package:timer_grobi/providers/location_provider.dart';
import 'package:timer_grobi/screens/clock_screen.dart';

import '../helpers.dart';

Future<ProviderContainer> pumpClock(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
        child: localizedApp(const Scaffold(body: ClockScreen()))),
  );
  // لا pumpAndSettle: نبضة الثانية تُبقي الإطارات مجدولة دائماً.
  await tester.pump(const Duration(milliseconds: 100));
  return ProviderScope.containerOf(tester.element(find.byType(ClockScreen)));
}

void main() {
  testWidgets('الموقع الافتراضي ⇒ شريط تنبيه، واختيار مدينة يخفيه',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = await pumpClock(tester);

    expect(find.byType(DefaultLocationBanner), findsOneWidget);
    expect(find.textContaining('افتراضي'), findsOneWidget);

    await tester.tap(find.text('تحديد'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // حركة الورقة
    expect(find.text('تحديد الموقع'), findsOneWidget);

    await tester.tap(find.text('الرياض'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(DefaultLocationBanner), findsNothing);
    expect(find.text('الرياض، السعودية'), findsOneWidget);
    expect(container.read(locationProvider).isManual, isTrue);
  });

  testWidgets('موقع GPS مخزَّن ⇒ لا شريط تنبيه', (tester) async {
    SharedPreferences.setMockInitialValues({
      'location.last': jsonEncode(const LocationData(
              latitude: 24.7136, longitude: 46.6753, source: LocationSource.gps)
          .toJson()),
    });
    await pumpClock(tester);
    expect(find.byType(DefaultLocationBanner), findsNothing);
    expect(find.text('موقع GPS'), findsOneWidget);
  });
}
