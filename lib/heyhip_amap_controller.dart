import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/camera_position.dart';
import 'package:heyhip_amap/heyhip_marker.dart';
import 'package:heyhip_amap/heyhip_poi.dart';
import 'package:heyhip_amap/map_type.dart';

typedef MapClickCallback = void Function(LatLng latLng);
typedef CameraMoveStartCallback = void Function(CameraPosition position);
typedef CameraMoveCallback = void Function(CameraPosition position);
typedef CameraIdleCallback = void Function(CameraPosition position);
typedef MarkerClickCallback = void Function(String markerId, LatLng position);
typedef MarkerPopupToggleCallback =
    void Function(
      String markerId,
      bool isOpen,
      double? latitude,
      double? longitude,
    );

// 地图控制器
class HeyhipAmapController {
  MethodChannel? _channel;

  VoidCallback? _onMapLoaded;

  double? _initialLatitude;
  double? _initialLongitude;
  double? _initialZoom;

  bool _mapReady = false;

  bool _disposed = false;

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
    if (_disposed) return;

    _channel = MethodChannel('heyhip_amap_map_$viewId');

    // 接收事件
    _channel!.setMethodCallHandler((call) async {
      // 开始
      switch (call.method) {
        case 'onMapLoaded':
          markMapReady();
              // ✅ 通知外部：地图真正 ready
            _onMapLoaded?.call();
          break;

        case 'onMarkerClick':
          if (call.arguments is! Map) return;
          final map = Map<String, dynamic>.from(call.arguments);
          final markerId = map['markerId'] as String;
          final lat = map['latitude'] as double;
          final lng = map['longitude'] as double;

          _onMarkerClick?.call(markerId, LatLng(lat, lng));
          break;

        case 'onMapClick':
          if (call.arguments is! Map) return;
          final map = Map<String, dynamic>.from(call.arguments);
          final lat = map['latitude'] as double;
          final lng = map['longitude'] as double;

          _onMapClick?.call(LatLng(lat, lng));
          break;

        case 'onCameraIdle':
          if (call.arguments is! Map) return;
          final map = Map<String, dynamic>.from(call.arguments);
          _onCameraIdle?.call(CameraPosition.fromMap(map));
          break;

        case 'onCameraMove':
          if (call.arguments is! Map) return;
          final map = Map<String, dynamic>.from(call.arguments);
          _onCameraMove?.call(CameraPosition.fromMap(map));
          break;

        case 'onCameraMoveStart':
          if (call.arguments is! Map) return;
          final map = Map<String, dynamic>.from(call.arguments);
          _onCameraMoveStart?.call(CameraPosition.fromMap(map));
          break;

        case 'onMarkerPopupToggle':
          if (call.arguments is! Map) return;
          final map = Map<String, dynamic>.from(call.arguments);

          final markerId = map['markerId'] as String?;
          final action = map['action'] as String?;

          if (markerId != null && action != null) {
            final isOpen = action == 'open';
            final latitude = (map['latitude'] as num?)?.toDouble();
            final longitude = (map['longitude'] as num?)?.toDouble();

            _onMarkerPopupToggle?.call(markerId, isOpen, latitude, longitude);
          }
          break;

        default:
          debugPrint('未知 native 方法: ${call.method}');
      }
    });

  }

  // 高德地图完成
  void markMapReady() {
    if (_mapReady) return;

    _mapReady = true;

    // ✅ 先应用初始相机（如果有）
    if (_initialLatitude != null && _initialLongitude != null) {
      moveCamera(
        CameraPosition(
          target: LatLng(_initialLatitude!, _initialLongitude!),
          zoom: _initialZoom ?? 14,
        ),
      );

      // 只执行一次
      _initialLatitude = null;
      _initialLongitude = null;
      _initialZoom = null;
    }

    // ⭐ 回放所有缓存操作
    for (final action in _pendingActions) {
      if (_disposed) break;
      action();
    }
    _pendingActions.clear();
  }

  // 注册高德地图完成
  void onMapLoaded(VoidCallback callback) {
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
    if (_disposed || _channel == null) {
      return;
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
    if (_disposed) return;

    Future<void> action() {
      return _channel!.invokeMethod('setZoom', {'zoom': zoom});
    }

    if (_mapReady) {
      await action();
    } else {
      _pendingActions.add(action);
    }
  }

  /// 获取当前相机位置
  Future<CameraPosition?> getCameraPosition() async {
    if (_disposed || _channel == null) {
      return null;
    }

    final raw = await _channel!.invokeMethod<Map>('getCameraPosition');
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw);

    return CameraPosition.fromMap(map);
  }

  // 设置Markers
  Future<void> setMarkers(List<HeyhipMarker> markers) async {
    if (_disposed || _channel == null) {
      return;
    }

    Future<void> action() {
      return _channel!.invokeMethod('setMarkers', {
        'markers': markers.map((e) => e.toMap()).toList(),
      });
    }

    if (_mapReady) {
      await action();
    } else {
      _pendingActions.add(action);
    }
  }

  /// 动态设置地图类型
  Future<void> setMapType(MapType mapType) async {
    if (_disposed || _channel == null) {
      return;
    }

    Future<void> action() {
      return _channel!.invokeMethod('setMapType', mapType.value);
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
    print(_disposed);
    print(_channel);
    if (_disposed || _channel == null) return [];
print("开始啦得到的");
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
    print("搜索是山山水水");
print(result?.length);
    if (_disposed || result == null) return [];

    return result
        .map((e) => HeyhipPoi.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<HeyhipPoi>> searchPoisByText(
    String keyword, {
    String? city,
    bool cityLimit = false,
    LatLng? location,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (_disposed || _channel == null) return [];

    final result = await _channel!.invokeMethod<List>('searchPoisByText', {
      'keyword': keyword,
      'city': city,
      'cityLimit': cityLimit,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'page': page,
      'pageSize': pageSize,
    });

    if (_disposed || result == null) return [];

    return result
        .map((e) => HeyhipPoi.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  
  Future<void> _detachNative() async {
    if (_disposed || _channel == null) return;

    try {
      await _channel!.invokeMethod('detach');
    } catch (_) {
      // native 已销毁时，这里允许静默失败
    }
  }


  void dispose() {
    if (_disposed) return;
    _detachNative();
  
     _disposed = true;
    _channel?.setMethodCallHandler(null);
    _channel = null;
    _mapReady = false;
    _onMapLoaded = null;
    _onMapClick = null;
    _onCameraMove = null;
    _onCameraMoveStart = null;
    _onCameraIdle = null;
    _onMarkerClick = null;
    _onMarkerPopupToggle = null;
    _pendingActions.clear();
  }




}
