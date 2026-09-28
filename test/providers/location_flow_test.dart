import 'package:adhan/adhan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/core/prayer_service.dart';
import 'package:timer_grobi/models/location_data.dart';
import 'package:timer_grobi/providers/location_provider.dart';
import 'package:timer_grobi/providers/time_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 5, 1);
  const jakarta = (lat: -6.2088, lon: 106.8456);

  test('بلا إذن ولا مخزَّن ⇒ الموقع الافتراضي، واختيار مدينة يغيّر المواقيت',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(locationProvider.notifier);
    await notifier.ready; // GPS غير متاح في الاختبار ⇒ يبقى الاحتياطي
    expect(container.read(locationProvider).isFallback, isTrue);
    final meccaTimes = container.read(prayerDayProvider(date));

    notifier.setManual(jakarta.lat, jakarta.lon);
    final loc = container.read(locationProvider);
    expect(loc.isManual, isTrue);
    expect(loc.isFallback, isFalse);

    final times = container.read(prayerDayProvider(date));
    expect(times.maghrib, isNot(meccaTimes.maghrib));
    expect(
        times.maghrib,
        computeDayTimes(
                const LocationData(latitude: -6.2088, longitude: 106.8456),
                date,
                CalculationMethod.umm_al_qura)
            .maghrib);
  });

  test('الموقع اليدوي يُحفظ ويُستعاد يدوياً عند الإقلاع التالي', () async {
    SharedPreferences.setMockInitialValues({});
    final first = ProviderContainer();
    await first.read(locationProvider.notifier).ready;
    first
        .read(locationProvider.notifier)
        .setManual(30.0444, 31.2357, cityId: 'eg/cairo');
    await Future<void>.delayed(Duration.zero); // الحفظ غير متزامن
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    await second.read(locationProvider.notifier).ready;
    final loc = second.read(locationProvider);
    expect(loc.isManual, isTrue);
    expect(loc.cityId, 'eg/cairo');
    expect(loc.latitude, 30.0444);
  });

  test('لا يُعرض شرح الإذن حين لا يدعم النظام الموقع أو سبق السؤال', () async {
    SharedPreferences.setMockInitialValues({'location.permissionAsked': true});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
        await container.read(locationProvider.notifier).shouldExplainPermission(),
        isFalse);
  });

  test('رسائل فشل GPS', () {
    expect(gpsResultMessage(GpsResult.ok), isNull);
    for (final r in GpsResult.values.where((r) => r != GpsResult.ok)) {
      expect(gpsResultMessage(r), isNotEmpty);
    }
  });
}
