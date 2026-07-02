import 'astronomy.dart';

/// وقت من اليوم بدقّة الثانية (تمثيل للساعة الشمسية، لا تاريخ مرتبط بمنطقة).
class SolarTimeOfDay {
  final int hour; // 0–23
  final int minute; // 0–59
  final int second; // 0–59

  const SolarTimeOfDay(this.hour, this.minute, this.second);

  /// إجمالي الدقائق منذ منتصف الليل الشمسي (لأغراض المقارنة/الاختبار).
  double get totalMinutes => hour * 60 + minute + second / 60.0;

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// يحوّل لحظة [instant] إلى **التوقيت الشمسي الحقيقي (الظاهري)** عند خط الطول
/// [longitudeDeg]، اعتماداً على خط الطول من GPS ومعادلة الزمن — **لا** على
/// المنطقة الزمنية. عند هذا التوقيت تكون الشمس في كبد السماء (الزوال) ≈ 12:00.
///
/// المعادلة: `solar = UTC + (lon/15) ساعة + EoT`.
SolarTimeOfDay solarTime(DateTime instant, double longitudeDeg) {
  final utc = instant.toUtc();
  final lonMillis = (longitudeDeg / 15.0 * 3600000.0).round();
  final eotMillis = (equationOfTime(utc) * 60000.0).round();
  final solar = utc.add(Duration(milliseconds: lonMillis + eotMillis));
  return SolarTimeOfDay(solar.hour, solar.minute, solar.second);
}
