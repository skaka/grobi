/// مصدر الموقع المستخدَم في الحساب.
enum LocationSource {
  /// لم يُحدَّد موقع بعد (رُفض الإذن أو لم يُمنح) — مكة المكرمة مؤقتاً.
  fallback,

  /// من GPS.
  gps,

  /// اختاره المستخدم يدوياً (مدينة من القائمة أو إحداثيات).
  manual,
}

/// موقع المستخدم: إحداثيات + ارتفاع عن سطح البحر (بالأمتار) + مصدره.
///
/// الارتفاع لم يعد يدخل في حساب المواقيت (انظر `computeDayTimes`)، ويُحفظ للعرض
/// والتشخيص فقط. وارتفاع GPS إهليلجي لا فوق سطح البحر، فلا يُعتمد عليه.
class LocationData {
  final double latitude;
  final double longitude;
  final double altitude; // متر (من GPS، للمعلومية)
  final LocationSource source;
  final String? label; // وصف حرّ قديم (النسخ السابقة كانت تحفظ اسم المدينة نصاً)
  final String? cityId; // مدينة من القائمة المضمَّنة (`sa/riyadh`) — يُعرض اسمها بلغة الواجهة

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.source = LocationSource.gps,
    this.label,
    this.cityId,
  });

  /// موقع افتراضي (مكة المكرمة) إلى أن يتوفّر GPS أو يختار المستخدم موقعه.
  static const LocationData fallback = LocationData(
    latitude: 21.4225,
    longitude: 39.8262,
    source: LocationSource.fallback,
    cityId: 'sa/mecca',
  );

  bool get isFallback => source == LocationSource.fallback;
  bool get isManual => source == LocationSource.manual;

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    LocationSource? source,
    String? label,
    String? cityId,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      source: source ?? this.source,
      label: label ?? this.label,
      cityId: cityId ?? this.cityId,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'source': source.name,
        'label': label,
        'cityId': cityId,
      };

  /// يقرأ أيضاً الصيغة القديمة (`isManual` بلا `source`): المخزَّن قديماً كان من
  /// GPS دائماً، إذ لم يكن في التطبيق أي طريق لتعيين موقع يدوي.
  factory LocationData.fromJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String?;
    final source = LocationSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => json['isManual'] == true
          ? LocationSource.manual
          : LocationSource.gps,
    );
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
      source: source,
      label: json['label'] as String?,
      cityId: json['cityId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LocationData &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.altitude == altitude &&
      other.source == source &&
      other.label == label &&
      other.cityId == cityId;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, altitude, source, label, cityId);
}
