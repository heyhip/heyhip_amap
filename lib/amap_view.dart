import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AMapView extends StatelessWidget {
  const AMapView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidView(
        viewType: 'heyhip_amap_map',
      );
    }

    return const Text('AMapView is only supported on Android');
  }
}
