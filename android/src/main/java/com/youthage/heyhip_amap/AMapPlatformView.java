package com.youthage.heyhip_amap;

import android.content.Context;
import android.view.View;

import com.amap.api.maps.MapView;
import com.amap.api.maps.AMap;

import io.flutter.plugin.platform.PlatformView;

public class AMapPlatformView implements PlatformView {

    private final MapView mapView;

    AMapPlatformView(Context context) {
        mapView = new MapView(context);
        mapView.onCreate(null);

        AMap aMap = mapView.getMap();
        aMap.getUiSettings().setZoomControlsEnabled(true);
        aMap.setMyLocationEnabled(true);
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        mapView.onDestroy();
    }
}
