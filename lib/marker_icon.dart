import 'dart:typed_data';

class MarkerIcon {
  final String type;
  final dynamic value;
  final double width;
  final double height;

  const MarkerIcon._(
    this.type,
    this.value, {
    this.width = 120,
    this.height = 120,
  });

  /// asset 图标
  factory MarkerIcon.asset(
    String assetPath, {
    double width = 120,
    double height = 120,
  }) {
    return MarkerIcon._('asset', assetPath, width: width, height: height);
  }

  /// 网络图标
  factory MarkerIcon.network(
    String url, {
    double width = 120,
    double height = 120,
  }) {
    return MarkerIcon._('network', url, width: width, height: height);
  }

  /// base64 图标
  factory MarkerIcon.base64(
    String base64, {
    double width = 120,
    double height = 120,
  }) {
    return MarkerIcon._('base64', base64, width: width, height: height);
  }

  /// ⚠️ bitmap（不建议 Flutter → 原生）
  factory MarkerIcon.bitmap(
    Uint8List bytes, {
    double width = 120,
    double height = 120,
  }) {
    return MarkerIcon._('bitmap', bytes, width: width, height: height);
  }

  /// ⭐ 给 Platform Channel 用
  Map<String, dynamic> toMap() {
    return {
      'icon': {'type': type, 'value': value},
      'iconWidth': width,
      'iconHeight': height,
    };
  }
}
