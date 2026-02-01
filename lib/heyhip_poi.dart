import 'camera_position.dart';

class HeyhipPoi {
  final String? id;
  final String? name;
  final LatLng position;
  final String? address;
  final String? type;
  final double? distance;

  final String? province;
  final String? city;
  final String? district;

  HeyhipPoi({
    this.id,
    this.name,
    required this.position,
    this.address,
    this.type,
    this.distance,
    this.province,
    this.city,
    this.district,
  });

  /// 根据 adcode 推断市级 adcode
  static String? getCityByAdcode(String? adcode) {
    if (adcode == null || adcode.length != 6) return null;

    final provinceCode = adcode.substring(0, 2);

    // 四大直辖市
    const municipalities = {'11', '12', '31', '50'};
    if (municipalities.contains(provinceCode)) {
      return '${provinceCode}0100';
    }

    // 普通地级市
    return '${adcode.substring(0, 4)}00';
  }

  factory HeyhipPoi.fromMap(Map<String, dynamic> map) {
    final adcode = map['adcode'] as String?;

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

      province: map['pcode'] as String?,
      city: HeyhipPoi.getCityByAdcode(adcode),
      district: adcode,
    );
  }
}
