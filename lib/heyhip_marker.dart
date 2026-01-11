import 'package:heyhip_amap/marker_icon.dart';

class HeyhipMarker {
  /// 唯一标识（diff / 点击 / 聚合都靠它）
  final String id;

  final double latitude;
  final double longitude;

  final MarkerIcon? icon;

  const HeyhipMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.icon,
  });

  /// ⭐ 统一协议：Android / iOS 共用
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
    };

    if (icon != null) {
      // ⭐ 关键：展开，而不是再包一层 icon
      map.addAll(icon!.toMap());
    }

    return map;
  }
}
