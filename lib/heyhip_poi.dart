import 'camera_position.dart';

class HeyhipPoi {
  final String? id;
  final String? name;
  final LatLng? position;
  final String? address;
  final String? type;
  final double? distance;
  final String? pcode;
  final String? adcode;

  HeyhipPoi({
    this.id,
    this.name,
    this.position,
    this.address,
    this.type,
    this.distance,
    this.pcode,
    this.adcode,
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
      pcode: map['pcode'] as String? ?? '',
      adcode: map['adcode'] as String? ?? '',
    );
  }
}
