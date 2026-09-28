import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../models/location_data.dart';
import '../services/geomagnetic.dart';

/// نتيجة محاولة تحديد الموقع من GPS (ليعرض الواجهة سبب الفشل).
enum GpsResult { ok, serviceDisabled, denied, deniedForever, unavailable }

/// يوفّر موقع المستخدم: يبدأ بالمخزّن/الافتراضي فوراً، ثم يحدّثه من GPS **إن كان
/// الإذن ممنوحاً مسبقاً** — طلب الإذن نفسه لا يجري إلا بفعل صريح من الواجهة
/// ([requestGps]) بعد شرح السبب، كي لا يتزاحم مع طلبات أذونات أخرى عند الإقلاع
/// (أندرويد يُسقط كل طلب متزامن عدا واحداً).
class LocationNotifier extends Notifier<LocationData> {
  static const _kLocation = 'location.last';
  static const _kPermissionAsked = 'location.permissionAsked';

  late Future<void> _ready;

  /// يكتمل بعد تحميل الموقع المخزّن ومحاولة GPS الصامتة الأولى.
  Future<void> get ready => _ready;

  @override
  LocationData build() {
    _ready = _init();
    return LocationData.fallback; // حتى يصل المخزّن/GPS
  }

  Future<void> _init() async {
    try {
      final p = await SharedPreferences.getInstance();
      final cached = p.getString(_kLocation);
      if (cached != null) {
        state = LocationData.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      }
    } catch (_) {/* تجاهل المخزّن التالف أو منصّة بلا تخزين */}
    // الموقع اليدوي اختيار صريح من المستخدم: لا يطغى عليه GPS تلقائياً.
    if (!state.isManual) await refreshFromGps(request: false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocation, jsonEncode(state.toJson()));
  }

  /// هل نعرض شرح طلب الإذن الآن؟ مرة واحدة فقط لكل تثبيت، وحين لا موقع يدوي
  /// ولا إذن ممنوح ولا رفض نهائي. بعدها يبقى الشريط التنبيهي طريقَ المستخدم.
  Future<bool> shouldExplainPermission() async {
    await ready;
    if (state.isManual) return false;
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_kPermissionAsked) ?? false) return false;
      return await Geolocator.checkPermission() == LocationPermission.denied;
    } catch (_) {
      return false; // منصّة لا تدعم الموقع (مثل Linux desktop أو الاختبارات)
    }
  }

  Future<void> markPermissionExplained() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPermissionAsked, true);
  }

  /// يطلب الإذن (إن لزم) ثم يحدّث الموقع من GPS — بفعل صريح من المستخدم.
  Future<GpsResult> requestGps() => refreshFromGps(request: true);

  /// يحاول تحديث الموقع من GPS؛ عند الفشل يُبقي الحالة الحالية. لا يطلب الإذن
  /// إلا إن كان [request] = true.
  Future<GpsResult> refreshFromGps({bool request = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return GpsResult.serviceDisabled;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && request) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return GpsResult.deniedForever;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return GpsResult.denied;
      }

      final pos = await _currentPosition();
      if (pos == null) return GpsResult.unavailable;
      state = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        source: LocationSource.gps,
      );
      await _save();
      return GpsResult.ok;
    } catch (_) {
      // منصّة غير مدعومة أو مهلة/خطأ — نُبقي الموقع المخزّن/الافتراضي.
      return GpsResult.unavailable;
    }
  }

  /// الموقع الحالي بدقّة تناسب الإذن الممنوح. من منح «الموقع التقريبي» فقط لا يصله
  /// إصلاح عالي الدقّة أبداً (يفشل بعد المهلة ويبقى على الافتراضي)، فنطلب دقّة
  /// منخفضة (مستوى المدينة يكفي: كل كيلومتر ≈ ثانيتين إلى أربع في المواقيت). وعند
  /// انقضاء المهلة (داخل مبنى مثلاً) نكتفي بآخر موقع معروف للجهاز.
  Future<Position?> _currentPosition() async {
    var accuracy = LocationAccuracy.medium;
    try {
      if (await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.reduced) {
        accuracy = LocationAccuracy.low;
      }
    } catch (_) {/* منصّة لا تُميّز الدقّة — نُبقي المتوسّطة */}
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: const Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      return Geolocator.getLastKnownPosition();
    }
  }

  /// تعيين موقع يدوي (مدينة من القائمة أو إحداثيات) — يُلغي الاعتماد على GPS
  /// حتى يطلبه المستخدم ثانيةً.
  void setManual(double latitude, double longitude, {String? cityId}) {
    state = LocationData(
      latitude: latitude,
      longitude: longitude,
      source: LocationSource.manual,
      cityId: cityId,
    );
    _save();
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationData>(LocationNotifier.new);

/// الانحراف المغناطيسي عند الموقع الحالي (null إن لم يتوفّر على المنصّة). يتغيّر
/// ببطء شديد مكاناً وزماناً، فلا يُعاد حسابه إلا عند تغيّر الموقع.
final declinationProvider = FutureProvider<double?>((ref) {
  final (lat, lon) =
      ref.watch(locationProvider.select((l) => (l.latitude, l.longitude)));
  return Geomagnetic.declination(lat, lon);
});

/// رسالة (بلغة الواجهة) لنتيجة GPS فاشلة، أو null عند النجاح.
String? gpsResultMessage(GpsResult r) {
  switch (r) {
    case GpsResult.ok:
      return null;
    case GpsResult.serviceDisabled:
      return tr.gpsServiceDisabled;
    case GpsResult.denied:
      return tr.gpsDenied;
    case GpsResult.deniedForever:
      return tr.gpsDeniedForever;
    case GpsResult.unavailable:
      return tr.gpsUnavailable;
  }
}
