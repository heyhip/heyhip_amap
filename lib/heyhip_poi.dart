import 'dart:ffi';

import 'camera_position.dart';

class HeyhipPoi {
  final String id;
  final String name;
  final LatLng position;
  final String address;
  final String type;
  final double? distance;

  HeyhipPoi({
    required this.id,
    required this.name,
    required this.position,
    required this.address,
    required this.type,
    this.distance,
  });

  factory HeyhipPoi.fromMap(Map<String, dynamic> map) {
    return HeyhipPoi(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      position: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      address: map['address'] as String? ?? '',
      type: map['type'] as String? ?? '',
      distance: (map['distance'] as num?)?.toDouble(),
    );
  }
}
