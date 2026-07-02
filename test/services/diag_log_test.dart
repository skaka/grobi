import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_grobi/services/diag_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  String msg(String line) => line.split('\t').last;

  test('يضيف ويُرجِع بالترتيب الزمني (الأقدم أولاً)', () async {
    await DiagLog.add('a', 'one');
    await DiagLog.add('b', 'two');
    final e = await DiagLog.entries();
    expect(e.length, 2);
    expect(msg(e.first), 'one');
    expect(msg(e.last), 'two');
  });

  test('لا يتجاوز السعة القصوى ويُسقِط الأقدم', () async {
    for (var i = 0; i < DiagLog.maxEntries + 25; i++) {
      await DiagLog.add('t', 'm$i');
    }
    final e = await DiagLog.entries();
    expect(e.length, DiagLog.maxEntries);
    expect(msg(e.first), 'm25'); // 225 مُدخَلاً ⇒ تبقى آخر 200 (تبدأ من m25)
    expect(msg(e.last), 'm${DiagLog.maxEntries + 24}');
  });

  test('يحوّل الفواصل/الأسطر في الرسالة كي لا تكسر التنسيق', () async {
    await DiagLog.add('t', 'a\tb\nc');
    final e = await DiagLog.entries();
    expect(msg(e.first), 'a b c');
  });

  test('المسح يفرّغ السجل', () async {
    await DiagLog.add('t', 'x');
    await DiagLog.clear();
    expect(await DiagLog.entries(), isEmpty);
  });
}
