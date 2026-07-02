import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_data.dart';

/// يوفّر موقع المستخدم: يبدأ بالمخزّن/الافتراضي فوراً، ثم يحاول GPS.
/// يتعامل بسلاسة مع المنصّات غير المدعومة (مثل Linux desktop) والأخطاء.
class LocationNotifier extends Notifier<LocationData> {
  static const _kLocation = 'location.last';

  @override
  LocationData build() {
    _init();
    return LocationData.mecca; // افتراضي حتى يصل المخزّن/GPS
  }

  Future<void> _init() async {
    final p = await SharedPreferences.getInstance();
    final cached = p.getString(_kLocation);
    if (cached != null) {
      try {
        state = LocationData.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {/* تجاهل المخزّن التالف */}
    }
    await refreshFromGps();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocation, jsonEncode(state.toJson()));
  }

  /// يحاول تحديث الموقع من GPS. عند الفشل/الرفض يُبقي الحالة الحالية.
  Future<void> refreshFromGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      state = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        isManual: false,
      );
      await _save();
    } catch (_) {
      // منصّة غير مدعومة أو خطأ — نُبقي الموقع المخزّن/الافتراضي.
    }
  }

  /// تعيين موقع يدوي (إحداثيات + ارتفاع).
  void setManual(double latitude, double longitude, double altitude) {
    state = LocationData(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      isManual: true,
    );
    _save();
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationData>(LocationNotifier.new);
