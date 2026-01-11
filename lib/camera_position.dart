class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
      };
      
  factory LatLng.fromMap(Map<String, dynamic> map) {
    return LatLng(
      (map['latitude'] as num).toDouble(),
      (map['longitude'] as num).toDouble(),
    );
  }
}

class CameraPosition {
  final LatLng target;
  final double? zoom;
  final double? tilt;
  final double? bearing;

  const CameraPosition({
    required this.target,
    this.zoom,
    this.tilt,
    this.bearing,
  });

  Map<String, dynamic> toMap() => {
        'target': target.toMap(),
        'zoom': zoom,
        'tilt': tilt,
        'bearing': bearing,
      };

  factory CameraPosition.fromMap(Map<String, dynamic> map) {
    return CameraPosition(
      target: LatLng.fromMap(
        Map<String, dynamic>.from(map),
      ),
      zoom: (map['zoom'] as num?)?.toDouble() ?? 14,
      tilt: (map['tilt'] as num?)?.toDouble() ?? 0,
      bearing: (map['bearing'] as num?)?.toDouble() ?? 0,
    );
  }

}
