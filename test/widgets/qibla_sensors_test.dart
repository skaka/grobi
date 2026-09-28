import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/providers/ui_providers.dart';
import 'package:timer_grobi/screens/qibla_screen.dart';

import '../helpers.dart';

const _accel = 'dev.fluttercommunity.plus/sensors/accelerometer';
const _mag = 'dev.fluttercommunity.plus/sensors/magnetometer';

void main() {
  late Map<String, List<String>> calls; // قناة ← [listen, cancel, ...]
  late List<Object?> orientations; // آخر طلبات تثبيت الاتجاه

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = {_accel: [], _mag: []};
    orientations = [];
    for (final name in [_accel, _mag]) {
      messenger().setMockMethodCallHandler(MethodChannel(name), (call) async {
        calls[name]!.add(call.method);
        return null;
      });
    }
    messenger().setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
        (_) async => null);
    messenger().setMockMethodCallHandler(
        const MethodChannel('com.misoor.grobi/geomagnetic'),
        (_) async => 3.5);
    messenger().setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientations.add(call.arguments);
      }
      return null;
    });
  });

  /// يرسل قراءة حسّاس عبر قناة الأحداث كما يفعل النظام.
  Future<void> emit(String channel, List<double> xyz) async {
    await messenger().handlePlatformMessage(
      channel,
      const StandardMethodCodec()
          .encodeSuccessEnvelope([...xyz, DateTime.now().microsecondsSinceEpoch.toDouble()]),
      (_) {},
    );
  }

  Future<ProviderContainer> pumpQibla(WidgetTester tester) async {
    await tester.pumpWidget(
        ProviderScope(child: localizedApp(const QiblaScreen())));
    await tester.pump();
    return ProviderScope.containerOf(tester.element(find.byType(QiblaScreen)));
  }

  testWidgets('الحسّاسات تعمل فقط والتبويب ظاهر والتطبيق في المقدّمة',
      (tester) async {
    final container = await pumpQibla(tester);
    expect(calls[_accel], isEmpty, reason: 'التبويب مخفي عند البناء');
    expect(calls[_mag], isEmpty);

    container.read(activeTabProvider.notifier).state = kQiblaTabIndex;
    await tester.pump();
    expect(calls[_accel], ['listen']);
    expect(calls[_mag], ['listen']);
    expect(orientations.last, ['DeviceOrientation.portraitUp']);

    container.read(activeTabProvider.notifier).state = 0;
    await tester.pump();
    expect(calls[_accel], ['listen', 'cancel']);
    expect(calls[_mag], ['listen', 'cancel']);
    expect(orientations.last, isEmpty, reason: 'يُحرَّر الاتجاه');

    // في الخلفية والتبويب ظاهر: توقّف ثم استئناف.
    container.read(activeTabProvider.notifier).state = kQiblaTabIndex;
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls[_mag]!.last, 'cancel');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls[_mag]!.last, 'listen');
  });

  testWidgets('الشمال حقيقي بالانحراف، وتلميح المعايرة عند التشويش',
      (tester) async {
    final container = await pumpQibla(tester);
    container.read(activeTabProvider.notifier).state = kQiblaTabIndex;
    await tester.pump();

    await emit(_accel, [0, 0, 9.8]);
    await emit(_mag, [0, 30, -30]); // ~٤٢ ميكروتسلا: مجال أرضي طبيعي
    await tester.pump();
    expect(find.textContaining('الشمال الحقيقي'), findsOneWidget);
    expect(find.textContaining('شرقاً'), findsOneWidget);
    expect(find.textContaining('الرقم ٨'), findsNothing);

    for (var i = 0; i < 40; i++) {
      await emit(_mag, [150, 150, 0]); // تشويش قوي
    }
    await tester.pump();
    expect(find.textContaining('الرقم ٨'), findsOneWidget);

    container.read(activeTabProvider.notifier).state = 0;
    await tester.pump();
  });
}
