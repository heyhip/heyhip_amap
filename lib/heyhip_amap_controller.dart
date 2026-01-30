import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/camera_position.dart';
import 'package:heyhip_amap/cluster_style.dart';
import 'package:heyhip_amap/heyhip_marker.dart';
import 'package:heyhip_amap/heyhip_poi.dart';

typedef MapClickCallback = void Function(LatLng latLng);
typedef CameraMoveStartCallback = void Function(CameraPosition position);
typedef CameraMoveCallback = void Function(CameraPosition position);
typedef CameraIdleCallback = void Function(CameraPosition position);
typedef MarkerClickCallback = void Function(
  String markerId,
  LatLng position,
);
typedef MarkerPopupToggleCallback = void Function(
  String markerId,
  bool isOpen,
  double? latitude,
  double? longitude,
);




// 地图控制器
class HeyhipAmapController {
  MethodChannel? _channel;
  bool _attached = false;

  VoidCallback? _onMapLoaded;

  double? _initialLatitude;
  double? _initialLongitude;
  double? _initialZoom;


  bool _mapReady = false;
  /// ⭐ 缓存的操作队列
  final List<Future<void> Function()> _pendingActions = [];


  // 地图点击
  MapClickCallback? _onMapClick;
  // 地图开始移动
  CameraMoveStartCallback? _onCameraMoveStart;
  // 地图移动完成
  CameraIdleCallback? _onCameraIdle;
  // 地图持续移动
  CameraMoveCallback? _onCameraMove;
  // Marker点击
  MarkerClickCallback? _onMarkerClick;
  // Marker点击弹窗
  MarkerPopupToggleCallback? _onMarkerPopupToggle;


  // 初始化相机
  void initialCamera({
    required double latitude,
    required double longitude,
    double zoom = 14,
  }) {
    _initialLatitude = latitude;
    _initialLongitude = longitude;
    _initialZoom = zoom;
  }

  
  // 绑定视图
  void attach(int viewId) {
    if (_attached) return;

    _channel = MethodChannel('heyhip_amap_map_$viewId');

    // 接收事件
    _channel!.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMapLoaded':
          markMapReady();
          break;

        case 'onMarkerClick':
          final map = Map<String, dynamic>.from(call.arguments);
          final markerId = map['markerId'] as String;
          final lat = map['latitude'] as double;
          final lng = map['longitude'] as double;

          _onMarkerClick?.call(
            markerId,
            LatLng(lat, lng),
          );
          break;

        case 'onMapClick':
          final map = Map<String, dynamic>.from(call.arguments);
          final lat = map['latitude'] as double;
          final lng = map['longitude'] as double;

          _onMapClick?.call(LatLng(lat, lng));
          break;

        case 'onCameraIdle':
          final map = Map<String, dynamic>.from(call.arguments);
          _onCameraIdle?.call(CameraPosition.fromMap(map));
          break;

        case 'onCameraMove':
          final map = Map<String, dynamic>.from(call.arguments);
          _onCameraMove?.call(CameraPosition.fromMap(map));
          break;
        
        case 'onCameraMoveStart':
          final map = Map<String, dynamic>.from(call.arguments);
          _onCameraMoveStart?.call(CameraPosition.fromMap(map));
          break;

        case 'onMarkerPopupToggle':
          if (call.arguments is Map) {
            final map = Map<String, dynamic>.from(call.arguments);

            final markerId = map['markerId'] as String?;
            final action = map['action'] as String?;

            if (markerId != null && action != null) {
              final isOpen = action == 'open';
              final latitude = (map['latitude'] as num?)?.toDouble();
              final longitude = (map['longitude'] as num?)?.toDouble();

              _onMarkerPopupToggle?.call(
                markerId,
                isOpen,
                latitude,
                longitude,
              );
            }
          }
          break;

        default:
          debugPrint('未知 native 方法: ${call.method}');
      }
    });

    _attached = true;
  }

  // 高德地图完成
  void markMapReady() {
    if (_mapReady) return;

    _mapReady = true;

    // ✅ 先应用初始相机（如果有）
    if (_initialLatitude != null && _initialLongitude != null) {

      moveCamera(CameraPosition(target: LatLng(_initialLatitude!, _initialLongitude!), zoom: _initialZoom ?? 14));

      // 只执行一次
      _initialLatitude = null;
      _initialLongitude = null;
      _initialZoom = null;
    }

    // ✅ 通知外部：地图真正 ready
    _onMapLoaded?.call();

    // ⭐ 回放所有缓存操作
    for (final action in _pendingActions) {
      action();
    }
    _pendingActions.clear();
  }


  // 注册高德地图完成
  void onMapLoadFinish(VoidCallback callback) {
    _onMapLoaded = callback;
  }

  /// 注册地图点击事件
  void onMapClick(MapClickCallback callback) {
    _onMapClick = callback;
  }

  // 地图开始移动
  void onCameraMoveStart(CameraMoveStartCallback callback) {
    _onCameraMoveStart = callback;
  }

  // 地图持续移动
  void onCameraMove(CameraMoveCallback callback) {
    _onCameraMove = callback;
  }

  // 地图移动完成
  void onCameraIdle(CameraIdleCallback callback) {
    _onCameraIdle = callback;
  }

  // Marker点击
  void onMarkerClick(MarkerClickCallback callback) {
    _onMarkerClick = callback;
  }

  // Marker点击出现弹窗
  void onMarkerPopupToggle(MarkerPopupToggleCallback callback) {
    _onMarkerPopupToggle = callback;
  }


  // 移动地图
  Future<void> moveCamera(CameraPosition position) async {
    if (!_attached || _channel == null) {
      throw StateError('AMapController is not attached to a map');
    }

    Future<void> action() {
      return _channel!.invokeMethod('moveCamera', position.toMap());
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

  // 设置Markers
  Future<void> setMarkers(List<HeyhipMarker> markers) async {
    if (!_attached || _channel == null) {
      throw StateError('AMapController is not attached to a map');
    }

    Future<void> action() {
      return _channel!.invokeMethod(
        'setMarkers',
        {
          'markers': markers.map((e) => e.toMap()).toList(),
        },
      );
    }

    if (_mapReady) {
      await action();
    } else {
      _pendingActions.add(action);
    }
  }

  /// 动态设置地图类型
  Future<void> setMapType(int mapType) async {
    if (!_attached || _channel == null) {
      throw StateError('AMapController is not attached to a map');
    }

    Future<void> action() {
      return _channel!.invokeMethod('setMapType', mapType);
    }

    if (_mapReady) {
      await action();
    } else {
      _pendingActions.add(action);
    }
  }


  /// 根据经纬度获取周边Poi
  Future<List<HeyhipPoi>> searchPoisByLatLng(
    LatLng latlng, {
      int radius = 1000, 
      String keyword = '',
      int page = 1,
      int pageSize = 20,
      }) async {
    final result = await _channel!.invokeMethod<List<dynamic>>(
      'searchPoisByLatLng',
      {
        'latitude': latlng.latitude,
        'longitude': latlng.longitude,
        'radius': radius,
        'keyword': keyword, // 可选
        'page': page,
        'pageSize': pageSize,
      },
    );

    if (result == null) return [];

    return result
      .map((e) => HeyhipPoi.fromMap(Map<String, dynamic>.from(e)))
      .toList();
  }




}
