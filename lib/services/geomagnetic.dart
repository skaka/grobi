import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// الانحراف المغناطيسي المحلي من النظام دون إنترنت: على أندرويد عبر
/// `android.hardware.GeomagneticField` (نموذج WMM المضمَّن في النظام) من خلال قناة
/// في `MainActivity.kt`. المنصّات بلا تنفيذ (iOS حالياً، الويب) تُعيد null فيبقى
/// الاتجاه مغناطيسياً.
class Geomagnetic {
  static const MethodChannel _channel =
      MethodChannel('com.misoor.grobi/geomagnetic');

  /// الانحراف بالدرجات (شرقاً موجب)، أو null إن تعذّر.
  static Future<double?> declination(double latitude, double longitude) async {
    if (kIsWeb) return null;
    try {
      return await _channel.invokeMethod<double>('declination', {
        'latitude': latitude,
        'longitude': longitude,
      });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
