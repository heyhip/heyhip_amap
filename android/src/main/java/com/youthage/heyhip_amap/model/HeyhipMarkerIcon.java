package com.youthage.heyhip_amap.model;

import androidx.annotation.Nullable;

import java.util.Map;

public class HeyhipMarkerIcon {

    public enum IconType {
        asset,
        network,
        base64
    }

    public final IconType type;
    public final String value;
    public final int width;
    public final int height;

    private HeyhipMarkerIcon(
            IconType type,
            String value,
            int width,
            int height
    ) {
        this.type = type;
        this.value = value;
        this.width = width;
        this.height = height;
    }

    @Nullable
    @SuppressWarnings("unchecked")
    public static HeyhipMarkerIcon fromMap(Object obj) {

        if (!(obj instanceof Map)) return null;

        Map<String, Object> map = (Map<String, Object>) obj;

        Object typeObj = map.get("type");
        Object valueObj = map.get("value");

        if (!(typeObj instanceof String) || !(valueObj instanceof String)) {
            return null;
        }

        IconType type;
        try {
            type = IconType.valueOf((String) typeObj);
        } catch (IllegalArgumentException e) {
            return null;
        }

        int width = map.get("width") instanceof Number
                ? ((Number) map.get("width")).intValue()
                : 48;

        int height = map.get("height") instanceof Number
                ? ((Number) map.get("height")).intValue()
                : 48;

        return new HeyhipMarkerIcon(
                type,
                (String) valueObj,
                width,
                height
        );
    }
}
