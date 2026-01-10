import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/heyhip_amap_controller.dart';

class HeyhipAmapView extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? zoom;

   /// ✅ 外部传入的 Controller
  final HeyhipAmapController controller;

  /// ✅ 新增：地图创建完成回调
  final VoidCallback? onMapCreated;

  const HeyhipAmapView({
    super.key,
    this.latitude,
    this.longitude,
    this.zoom = 15,
    required this.controller,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'heyhip_amap_map',
      creationParams: {
        'latitude': latitude,
        'longitude': longitude,
        'zoom': zoom,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int viewId) {
    controller.attach(viewId);
    onMapCreated?.call();
  }

}

