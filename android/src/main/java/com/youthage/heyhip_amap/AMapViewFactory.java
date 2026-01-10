package com.youthage.heyhip_amap;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class AMapViewFactory extends PlatformViewFactory {

    AMapViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    @SuppressWarnings("unchecked")
    @NonNull
    @Override
    public PlatformView create(Context context, int viewId, @Nullable Object args) {
        // Map<String, Object> params = (Map<String, Object>) args;

        Map<String, Object> params = new HashMap<>();

        if (args instanceof Map) {
            params = (Map<String, Object>) args;
        }
        
        return new AMapPlatformView(context, viewId, params);
    }
}
