package com.misoor.grobi

import android.app.LocaleManager
import android.hardware.GeomagneticField
import android.os.Build
import android.os.LocaleList
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // الانحراف المغناطيسي المحلي (دون إنترنت) من نموذج WMM المضمَّن في النظام،
        // لتحويل اتجاه البوصلة المغناطيسي إلى حقيقي في شاشة القبلة.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.misoor.grobi/geomagnetic")
            .setMethodCallHandler { call, result ->
                if (call.method != "declination") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                if (latitude == null || longitude == null) {
                    result.error("bad_args", "latitude/longitude مطلوبان", null)
                    return@setMethodCallHandler
                }
                val field = GeomagneticField(
                    latitude.toFloat(),
                    longitude.toFloat(),
                    0f, // الارتفاع لا يغيّر الانحراف عملياً (أجزاء من الدرجة لكل كيلومتر)
                    System.currentTimeMillis(),
                )
                result.success(field.declination.toDouble())
            }

        // لغة التطبيق في النظام (أندرويد 13+) تتبع اختيار المستخدم داخل التطبيق، كي
        // تُعرض إشعارات الخلفية (مفاتيح title_loc_key) بلغة الواجهة نفسها.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.misoor.grobi/locale")
            .setMethodCallHandler { call, result ->
                if (call.method != "setAppLanguage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                val code = call.argument<String>("code")
                getSystemService(LocaleManager::class.java).applicationLocales =
                    if (code == null) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(code)
                result.success(true)
            }
    }
}
