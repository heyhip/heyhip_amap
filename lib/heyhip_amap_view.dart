import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/amap_ui_settings.dart';
import 'package:heyhip_amap/cluster_style.dart';
import 'package:heyhip_amap/heyhip_amap_controller.dart';
import 'package:heyhip_amap/heyhip_marker.dart';
import 'package:heyhip_amap/heyhip_marker_popup.dart';
import 'package:heyhip_amap/map_type.dart';

class HeyhipAmapView extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? zoom;
  final MapType mapType;
  // 是否开启聚合
  final bool clusterEnabled;
  // 聚合样式
  final ClusterStyle? clusterStyle;
  /// 是否启用 marker 点击弹窗
  final bool enableMarkerPopup;


   /// ✅ 外部传入的 Controller
  final HeyhipAmapController controller;

  /// ✅ 新增：地图创建完成回调
  final VoidCallback? onMapCreated;

  /// ⭐ UI 设置
  final AMapUiSettings uiSettings;

  const HeyhipAmapView({
    super.key,
    this.latitude,
    this.longitude,
    this.zoom = 14,
    required this.controller,
    this.onMapCreated,
    this.uiSettings = const AMapUiSettings(),
    this.mapType = MapType.normal,
    this.clusterEnabled = false,
    this.clusterStyle,
    this.enableMarkerPopup = false,
  });

  @override
  Widget build(BuildContext context) {

    String viewType = 'heyhip_amap_map';
    final creationParams = {
        'latitude': latitude,
        'longitude': longitude,
        'zoom': zoom,
        'uiSettings': uiSettings.toMap(),
        'mapType': mapType.value,
        'clusterEnabled': clusterEnabled,
        'clusterStyle': clusterStyle?.toMap(),
        'enableMarkerPopup': enableMarkerPopup,
      };

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        );
    }

    return AndroidView(
      viewType: viewType,
      creationParams: creationParams,
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

