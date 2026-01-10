package com.youthage.heyhip_amap;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import com.amap.api.maps.CameraUpdate;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.AMap;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.LatLng;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class AMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler {

    private final MapView mapView;
    private final AMap aMap;
    private final MethodChannel channel;

    // 初始定位
    private Double initLatitude;
    private Double initLongitude;
    private Float initZoom;

    public AMapPlatformView(Context context, int id, Map<String, Object> params) {

        // 1️⃣ 创建 MapView
        mapView = new MapView(context);
        mapView.onCreate(null);

        // 2️⃣ 获取 AMap 实例
        aMap = mapView.getMap();

        aMap.setOnMapLoadedListener(new AMap.OnMapLoadedListener() {
            @Override
            public void onMapLoaded() {

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

        // 3️⃣ 初始化地图参数
        // if (params != null) {
        //     double latitude = getDouble(params.get("latitude"), 39.90923);
        //     double longitude = getDouble(params.get("longitude"), 116.397428);
        //     float zoom = getFloat(params.get("zoom"), 15f);
        //
        //     CameraPosition position = new CameraPosition(
        //             new LatLng(latitude, longitude),
        //             zoom,
        //             0,
        //             0
        //     );
        //     aMap.moveCamera(CameraUpdateFactory.newCameraPosition(position));
        // }

        if (params != null) {
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
        }


        // 4️⃣ 绑定 MethodChannel（重点）
        channel = new MethodChannel(
                FlutterEngineHolder.getMessenger(),
                "heyhip_amap_map_" + id
        );
        channel.setMethodCallHandler(this);

    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        // MAPS.remove(viewId);
        channel.setMethodCallHandler(null);
        mapView.onDestroy();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {

            case "moveCamera":
                handleMoveCamera(call, result);
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

    // ======================
    // 处理 moveCamera
    // ======================
    private void handleMoveCamera(MethodCall call, MethodChannel.Result result) {

        Double latitude = call.argument("latitude");
        Double longitude = call.argument("longitude");
        Double zoom = call.argument("zoom");

        if (latitude == null || longitude == null) {
            result.error("INVALID_ARGS", "latitude or longitude is null", null);
            return;
        }

        float zoomLevel = zoom != null ? zoom.floatValue() : aMap.getCameraPosition().zoom;

        CameraPosition position = new CameraPosition(
                new LatLng(latitude, longitude),
                zoomLevel,
                0,
                0
        );

        aMap.animateCamera(
                CameraUpdateFactory.newCameraPosition(position)
        );

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


    private void notifyMapLoaded() {
        channel.invokeMethod("onMapLoaded", null);
    }




}

