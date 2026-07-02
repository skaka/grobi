/// موقع المستخدم: إحداثيات + ارتفاع عن سطح البحر (بالأمتار).
class LocationData {
  final double latitude;
  final double longitude;
  final double altitude; // متر فوق سطح البحر
  final bool isManual; // أُدخل يدوياً (لا من GPS)

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.isManual = false,
  });

  /// موقع افتراضي (مكة المكرمة) لأول تشغيل قبل توفّر GPS.
  static const LocationData mecca = LocationData(
    latitude: 21.4225,
    longitude: 39.8262,
    altitude: 277,
    isManual: true,
  );

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    bool? isManual,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      isManual: isManual ?? this.isManual,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'isManual': isManual,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
        isManual: json['isManual'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is LocationData &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.altitude == altitude &&
      other.isManual == isManual;

  @override
  int get hashCode => Object.hash(latitude, longitude, altitude, isManual);
}
