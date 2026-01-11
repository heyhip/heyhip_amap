package com.youthage.heyhip_amap;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.UiSettings;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.LatLng;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class AMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler {

    private final int viewId;
    private final MapView mapView;
    private final AMap aMap;
    private MethodChannel channel;

    // 初始定位
    private Double initLatitude;
    private Double initLongitude;
    private Float initZoom;

    // 初始化地图类型
    private Integer initMapType;

    // 持续移动节流
    private static final long CAMERA_MOVE_THROTTLE_MS = 120;
    private long lastCameraMoveTime = 0;

    // 自定义，用于有开始移动功能
    private boolean isCameraMoving = false;

    // 保存所有 marker
    private final Map<String, com.amap.api.maps.model.Marker> markers = new HashMap<>();


    public AMapPlatformView(Context context, int id, Map<String, Object> params) {
        this.viewId = id;

        // 1️⃣ 创建 MapView
        mapView = new MapView(context);
        mapView.onCreate(null);

        // 2️⃣ 获取 AMap 实例
        aMap = mapView.getMap();

        // 监听地图完成
        aMap.setOnMapLoadedListener(new AMap.OnMapLoadedListener() {
            @Override
            public void onMapLoaded() {

                // 地图类型
                if (initMapType != null) {
                    applyMapType(initMapType);
                }

                // ui设置
                applyUiSettings(params);

                // ⭐ 只有传了经纬度，才做初始化定位
                if (initLatitude != null && initLongitude != null) {
                    CameraPosition position = new CameraPosition(
                            new LatLng(initLatitude, initLongitude),
                            initZoom != null ? initZoom : 14f,
                            0,
                            0
                    );
                    aMap.moveCamera(
                            CameraUpdateFactory.newCameraPosition(position)
                    );
                }


                notifyMapLoaded();
            }
        });

        // 监听地图点击
        aMap.setOnMapClickListener(new AMap.OnMapClickListener() {
            @Override
            public void onMapClick(LatLng latLng) {
                notifyMapClick(latLng);
            }
        });

        // 监听地图移动
        aMap.setOnCameraChangeListener(new AMap.OnCameraChangeListener() {

            @Override
            public void onCameraChange(CameraPosition cameraPosition) {

                // ⭐ 第一次进入 = 开始移动
                if (!isCameraMoving) {
                    isCameraMoving = true;
                    notifyCameraMoveStart(cameraPosition);
                }

                // ⭐ 地图正在拖动 / 缩放 / 旋转
                notifyCameraMoving(cameraPosition); // 持续（已节流）
            }

            @Override
            public void onCameraChangeFinish(CameraPosition cameraPosition) {
                isCameraMoving = false;

                // 可选：如果你将来要“结束回调”
                notifyCameraIdle(cameraPosition); // 完成（不节流）
            }
        });

        // 监听marker点击
        aMap.setOnMarkerClickListener(marker -> {

            if (channel == null) return true;

            Object tag = marker.getObject();
            if (!(tag instanceof String)) {
                return true;
            }

            String markerId = (String) tag;
            LatLng position = marker.getPosition();

            Map<String, Object> map = new HashMap<>();
            map.put("markerId", markerId);
            map.put("latitude", position.latitude);
            map.put("longitude", position.longitude);

            channel.invokeMethod("onMarkerClick", map);

            return true; // ⭐ 不穿透到地图
        });



        if (params != null) {

            // 初始定位
            Object lat = params.get("latitude");
            Object lng = params.get("longitude");
            Object zoom = params.get("zoom");
            if (lat instanceof Number && lng instanceof Number) {
                initLatitude = ((Number) lat).doubleValue();
                initLongitude = ((Number) lng).doubleValue();
                initZoom = zoom instanceof Number
                        ? ((Number) zoom).floatValue()
                        : 14f;
            }

            // 地图类型
            Object type = params.get("mapType");
            if (type instanceof Number) {
                initMapType = ((Number) type).intValue();
            }

        }


        // 4️⃣ 绑定 MethodChannel（重点）
        channel = new MethodChannel(
                HeyhipAmapPlugin.getMessenger(),
                "heyhip_amap_map_" + id
        );
        channel.setMethodCallHandler(this);

        // ⭐ 注册 MapView
        HeyhipAmapPlugin.MAP_VIEWS.put(id, this);
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        channel.setMethodCallHandler(null);
        mapView.onDestroy();

        // ⭐ 从注册表移除
        HeyhipAmapPlugin.MAP_VIEWS.remove(viewId);
    }

    void onResume() {
        mapView.onResume();
    }

    void onPause() {
        mapView.onPause();
    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "setMarkers":
                handleSetMarkers(call, result);
                break;
            case "moveCamera":
                moveCamera(call, result);
                break;
            case "setZoom":
                handleSetZoom(call, result);
                break;
            case "getCameraPosition":
                handleGetCameraPosition(result);
                break;

            default:
                result.notImplemented();
        }
    }

    // ui设置
    @SuppressWarnings("unchecked")
    private void applyUiSettings(Map<String, Object> params) {
        if (params == null) return;

        Object uiObj = params.get("uiSettings");
        if (!(uiObj instanceof Map)) return;

        Map<String, Object> ui = (Map<String, Object>) uiObj;
        UiSettings uiSettings = aMap.getUiSettings();

        Boolean zoomControls = (Boolean) ui.get("zoomControlsEnabled");
        if (zoomControls != null) {
            uiSettings.setZoomControlsEnabled(zoomControls);
        }

        Boolean compass = (Boolean) ui.get("compassEnabled");
        if (compass != null) {
            uiSettings.setCompassEnabled(compass);
        }

        Boolean scale = (Boolean) ui.get("scaleControlsEnabled");
        if (scale != null) {
            uiSettings.setScaleControlsEnabled(scale);
        }

        Boolean myLocation = (Boolean) ui.get("myLocationButtonEnabled");
        if (myLocation != null) {
            uiSettings.setMyLocationButtonEnabled(myLocation);
        }

        Boolean rotate = (Boolean) ui.get("rotateGesturesEnabled");
        if (rotate != null) {
            uiSettings.setRotateGesturesEnabled(rotate);
        }

        Boolean tilt = (Boolean) ui.get("tiltGesturesEnabled");
        if (tilt != null) {
            uiSettings.setTiltGesturesEnabled(tilt);
        }

        Boolean zoomGesture = (Boolean) ui.get("zoomGesturesEnabled");
        if (zoomGesture != null) {
            uiSettings.setZoomGesturesEnabled(zoomGesture);
        }
    }

    // 地图类型
    private void applyMapType(int type) {
        switch (type) {
            case 1:
                aMap.setMapType(AMap.MAP_TYPE_SATELLITE);
                break;

            case 2:
                aMap.setMapType(AMap.MAP_TYPE_NIGHT);
                break;

            case 3:
                aMap.setMapType(AMap.MAP_TYPE_NAVI);
                break;

            case 4:
                aMap.setMapType(AMap.MAP_TYPE_BUS);
                break;

            case 0:
            default:
                aMap.setMapType(AMap.MAP_TYPE_NORMAL);
                break;
        }
    }



    // 移动地图
    private void moveCamera(MethodCall call, MethodChannel.Result result) {

        Map<String, Object> target = call.argument("target");
        if (target == null) {
            result.error("INVALID_PARAM", "target is null", null);
            return;
        }

        Double lat = (Double) target.get("latitude");
        Double lng = (Double) target.get("longitude");
        Double zoom = call.argument("zoom");
        Double tilt = call.argument("tilt");
        Double bearing = call.argument("bearing");

        if (lat == null || lng == null) {
            result.error("INVALID_PARAM", "lat or lng is null", null);
            return;
        }

        CameraPosition current = aMap.getCameraPosition();

        CameraPosition position = new CameraPosition(
                new LatLng(lat, lng),
                zoom != null ? zoom.floatValue() : current.zoom,
                tilt != null ? tilt.floatValue() : current.tilt,
                bearing != null ? bearing.floatValue() : current.bearing
        );


        aMap.animateCamera(CameraUpdateFactory.newCameraPosition(position));
        result.success(null);
    }

    // 设置Marker
    @SuppressWarnings("unchecked")
    private void handleSetMarkers(MethodCall call, MethodChannel.Result result) {

        if (aMap == null) {
            result.error("NO_MAP", "AMap not ready", null);
            return;
        }

        Object listObj = call.argument("markers");
        if (!(listObj instanceof java.util.List)) {
            result.error("INVALID_PARAM", "markers is not a list", null);
            return;
        }

        List<Map<String, Object>> list = (List<Map<String, Object>>) listObj;

        // 🔥 先清空旧 marker（后续可以优化为 diff）
        for (com.amap.api.maps.model.Marker marker : markers.values()) {
            marker.remove();
        }
        markers.clear();

        for (Map<String, Object> item : list) {

            String id = (String) item.get("id");
            Object latObj = item.get("latitude");
            Object lngObj = item.get("longitude");

            if (id == null || !(latObj instanceof Number) || !(lngObj instanceof Number)) {
                continue;
            }

            LatLng latLng = new LatLng(
                    ((Number) latObj).doubleValue(),
                    ((Number) lngObj).doubleValue()
            );

            com.amap.api.maps.model.Marker marker = aMap.addMarker(
                    new com.amap.api.maps.model.MarkerOptions()
                            .position(latLng)
            );

            // ⭐ 保存 markerId
            marker.setObject(id);
            markers.put(id, marker);
        }

        result.success(null);
    }



    // ======================
    // 工具方法
    // ======================
    private double getDouble(Object value, double def) {
        return value instanceof Number ? ((Number) value).doubleValue() : def;
    }

    private float getFloat(Object value, float def) {
        return value instanceof Number ? ((Number) value).floatValue() : def;
    }

    // 设置Zoom
    private void handleSetZoom(MethodCall call, MethodChannel.Result result) {
        if (aMap == null) {
            result.error("NO_MAP", "AMap not ready", null);
            return;
        }

        Double zoom = call.argument("zoom");
        if (zoom == null) {
            result.error("INVALID_PARAM", "zoom is null", null);
            return;
        }

        aMap.moveCamera(CameraUpdateFactory.zoomTo(zoom.floatValue()));
        result.success(null);
    }

    // 获取相机定位
    private void handleGetCameraPosition(MethodChannel.Result result) {
        if (aMap == null) {
            result.error("NO_MAP", "AMap not ready", null);
            return;
        }

        CameraPosition position = aMap.getCameraPosition();

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        result.success(map);
    }

    // 发送地图加载完成消息
    private void notifyMapLoaded() {
        if (channel == null) return;

        channel.invokeMethod("onMapLoaded", null);
    }

    // 发送地图点击消息
    private void notifyMapClick(LatLng latLng) {
        if (channel == null) return;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", latLng.latitude);
        map.put("longitude", latLng.longitude);

        channel.invokeMethod("onMapClick", map);
    }

    // 开始移动
    private void notifyCameraMoveStart(CameraPosition position) {
        if (channel == null) return;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        channel.invokeMethod("onCameraMoveStart", map);
    }

    // 发送持续移动位置
    private void notifyCameraMoving(CameraPosition position) {
        if (channel == null) return;

        long now = System.currentTimeMillis();
        if (now - lastCameraMoveTime < CAMERA_MOVE_THROTTLE_MS) {
            return;
        }

        lastCameraMoveTime = now;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        channel.invokeMethod("onCameraMove", map);
    }

    // 发送移动完成中心点消息
    private void notifyCameraIdle(CameraPosition position) {
        if (channel == null) return;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        channel.invokeMethod("onCameraIdle", map);
    }



}

