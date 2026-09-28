import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/providers/settings_provider.dart';
import 'package:timer_grobi/providers/time_providers.dart';

void main() {
  testWidgets('مواقيت يوم لا يراقبه أحد تُحرَّر بعد مهلة (لا تراكم بلا حد)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final day = DateTime(2026, 5, 1);

    final sub = container.listen(prayerDayProvider(day), (_, _) {});
    // تحميل الإعدادات والموقع غير المتزامن يعيد البناء؛ ومزوّد بلا مراقب تتغيّر
    // مدخلاته يُحرَّر فوراً (لا قيمة قديمة تبقى) — ننتظر استقرارها أولاً.
    await tester.pump(const Duration(seconds: 1));
    expect(container.exists(prayerDayProvider(day)), isTrue);
    sub.close();
    await tester.pump(const Duration(minutes: 4));
    expect(container.exists(prayerDayProvider(day)), isTrue,
        reason: 'يبقى مخزَّناً قليلاً بعد آخر مراقب');

    // عودة مراقب قبل المهلة تُلغيها.
    final again = container.listen(prayerDayProvider(day), (_, _) {});
    await tester.pump(const Duration(minutes: 10));
    expect(container.exists(prayerDayProvider(day)), isTrue);
    again.close();

    await tester.pump(const Duration(minutes: 6));
    expect(container.exists(prayerDayProvider(day)), isFalse);
  });

  test('مفاتيح الميزات المحذوفة تُمسح عند التحميل', () async {
    SharedPreferences.setMockInitialValues({
      'settings.autoCalibrate': true,
      'announcements.calibrated': ['ramadan_1447:1'],
      'settings.manualAltitude': 612.0,
      'settings.hijriAdjust': 1,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).ready;

    final p = await SharedPreferences.getInstance();
    expect(p.containsKey('settings.autoCalibrate'), isFalse);
    expect(p.containsKey('announcements.calibrated'), isFalse);
    expect(p.containsKey('settings.manualAltitude'), isFalse);
    expect(container.read(settingsProvider).hijriAdjust, 1,
        reason: 'الإعدادات الباقية لا تُمَسّ');
  });
}
