import 'package:flutter/services.dart';

// 地图控制器
class HeyhipAmapController {
  MethodChannel? _channel;
  bool _attached = false;

  VoidCallback? _onMapLoaded;


  bool _mapReady = false;
  /// ⭐ 缓存的操作队列
  final List<Future<void> Function()> _pendingActions = [];

  void markMapReady() {
    if (_mapReady) return;

    _mapReady = true;

    // ✅ 通知外部：地图真正 ready
    _onMapLoaded?.call();

    // ⭐ 回放所有缓存操作
    for (final action in _pendingActions) {
      action();
    }
    _pendingActions.clear();
  }


  void attach(int viewId) {
    if (_attached) return;

    _channel = MethodChannel('heyhip_amap_map_$viewId');

    // 设置初始化回调
    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'onMapLoaded') {
        // _onMapLoaded?.call();
        markMapReady();
      }
    });

    _attached = true;
  }

  void onMapLoadFinish(VoidCallback callback) {
    _onMapLoaded = callback;
  }

  /// 移动地图
  Future<void> moveCamera({
    required double latitude,
    required double longitude,
    double zoom = 14,
  }) async {
    if (!_attached || _channel == null) {
      throw StateError('AMapController is not attached to a map');
    }

    Future<void> action() {
      return _channel!.invokeMethod('moveCamera', {
        'latitude': latitude,
        'longitude': longitude,
        'zoom': zoom,
      });
    }

    if (_mapReady) {
      // ✅ 地图已 ready，直接执行
      await action();
    } else {
      // ⏳ 地图未 ready，缓存
      _pendingActions.add(action);
    }
  }


  /// 仅修改缩放级别
  Future<void> setZoom(double zoom) async {
    if (!_attached || _channel == null) {
      throw StateError('AMapController is not attached to a map');
    }

    await _channel!.invokeMethod('setZoom', {
      'zoom': zoom,
    });
  }

  /// 获取当前相机位置
  Future<Map<String, dynamic>> getCameraPosition() async {
    if (!_attached || _channel == null) {
      throw StateError('AMapController is not attached to a map');
    }

    final result = await _channel!.invokeMethod<Map>('getCameraPosition');
    return Map<String, dynamic>.from(result ?? {});
  }




}
