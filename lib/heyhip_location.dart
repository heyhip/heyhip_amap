import 'package:heyhip_amap/camera_position.dart';

class HeyhipLocation {
  final double latitude;
  final double longitude;
  /// 定位精度（Accuracy）
  ///
  /// - 单位：米（meters）
  /// - 数值越小，定位越精确
  /// - 常见值：
  ///   - GPS：5 ~ 20
  ///   - WiFi / 基站：20 ~ 100+
  /// - 可用于判断是否需要重新定位
  final double? accuracy;
  /// 移动速度（Speed）
  ///
  /// - 单位：米 / 秒（m/s）
  /// - 静止时通常为 0
  /// - 行走约 1 ~ 1.5
  /// - 开车可能 10 ~ 30+
  /// - 可用于导航、轨迹、运动状态判断
  final double? speed;
  /// 方向角 / 航向角（Bearing / Course）
  ///
  /// - 单位：度（°）
  /// - 范围：[0, 360)
  /// - 含义：
  ///   - 0   ：正北
  ///   - 90  ：正东
  ///   - 180 ：正南
  ///   - 270 ：正西
  /// - 仅在“移动中”才有意义
  final double? bearing;
  /// 定位时间戳
  ///
  /// - 单位：毫秒（milliseconds since epoch）
  /// - Unix 时间戳（1970-01-01）
  /// - 可用于：
  ///   - 判断定位数据是否过期
  ///   - 轨迹排序
  final int? timestamp;

  const HeyhipLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.bearing,
    this.timestamp,
  });

  factory HeyhipLocation.fromMap(Map<String, dynamic> map) {
    return HeyhipLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      bearing: (map['bearing'] as num?)?.toDouble(),
      timestamp: map['timestamp'] as int?,
    );
  }

  /// 如果你后面要丢给地图 / 统一结构
  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}
