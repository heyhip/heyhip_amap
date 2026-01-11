import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/amap_ui_settings.dart';
import 'package:heyhip_amap/cluster_style.dart';
import 'package:heyhip_amap/heyhip_amap_controller.dart';
import 'package:heyhip_amap/heyhip_marker.dart';
import 'package:heyhip_amap/map_type.dart';

class HeyhipAmapView extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? zoom;
  final MapType mapType;
  final bool clusterEnabled;
  final ClusterStyle? clusterStyle;


   /// ✅ 外部传入的 Controller
  final HeyhipAmapController controller;

  /// ✅ 新增：地图创建完成回调
  final VoidCallback? onMapCreated;

  /// ⭐ UI 设置
  final AMapUiSettings uiSettings;

  final List<HeyhipMarker>? markers;  

  const HeyhipAmapView({
    super.key,
    this.latitude,
    this.longitude,
    this.zoom = 14,
    required this.controller,
    this.onMapCreated,
    this.uiSettings = const AMapUiSettings(),
    this.mapType = MapType.normal,
    this.clusterEnabled = true,
    this.clusterStyle,
    this.markers,
  });

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'heyhip_amap_map',
      creationParams: {
        'latitude': latitude,
        'longitude': longitude,
        'zoom': zoom,
        'uiSettings': uiSettings.toMap(),
        'mapType': mapType.value,
        'clusterEnabled': clusterEnabled,
        'clusterStyle': clusterStyle?.toMap(),
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int viewId) {
    controller.attach(viewId);

    // ⭐ 把初始相机参数交给 controller
    if (latitude != null && longitude != null) {
      controller.initialCamera(
        latitude: latitude!,
        longitude: longitude!,
        zoom: zoom ?? 14,
      );
    }

    onMapCreated?.call();
  }

}

