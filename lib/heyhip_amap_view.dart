import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/amap_ui_settings.dart';
import 'package:heyhip_amap/cluster_style.dart';
import 'package:heyhip_amap/heyhip_amap_controller.dart';
import 'package:heyhip_amap/map_type.dart';

typedef HeyhipAmapViewCreatedCallback = void Function(HeyhipAmapController controller);

class HeyhipAmapView extends StatefulWidget {
  // const HeyhipAmapView({super.key});

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

  /// 是否开启持续移动
  final bool enableCameraMoving;

  /// ✅ 新增：地图创建完成回调
  final HeyhipAmapViewCreatedCallback? onMapCreated;

  /// ⭐ UI 设置
  final AMapUiSettings uiSettings;

  const HeyhipAmapView({
    super.key,
    this.latitude,
    this.longitude,
    this.zoom = 14,
    this.onMapCreated,
    this.uiSettings = const AMapUiSettings(),
    this.mapType = MapType.normal,
    this.clusterEnabled = false,
    this.clusterStyle,
    this.enableMarkerPopup = false,
    this.enableCameraMoving = false,
  });


  @override
  State<HeyhipAmapView> createState() => _HeyhipAmapViewState();
}

class _HeyhipAmapViewState extends State<HeyhipAmapView> {

  late final HeyhipAmapController _controller;

  /*
  @override
  void didUpdateWidget(covariant HeyhipAmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mapType != widget.mapType) {
      widget.controller.setMapType(widget.mapType.value);
    }
  }
  */

  @override
  void initState() {
    super.initState();
    _controller = HeyhipAmapController();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {

    String viewType = 'heyhip_amap_map';
    final creationParams = {
      'latitude': widget.latitude,
      'longitude': widget.longitude,
      'zoom': widget.zoom,
      'uiSettings': widget.uiSettings.toMap(),
      'mapType': widget.mapType.value,
      'clusterEnabled': widget.clusterEnabled,
      'clusterStyle': widget.clusterStyle?.toMap(),
      'enableMarkerPopup': widget.enableMarkerPopup,
      'enableCameraMoving': widget.enableCameraMoving,
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
    _controller.attach(viewId);

    // ⭐ 把初始相机参数交给 controller
    if (widget.latitude != null && widget.longitude != null) {
      _controller.initialCamera(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        zoom: widget.zoom ?? 14,
      );
    }

    widget.onMapCreated?.call(_controller);
  }


}
