package com.youthage.heyhip_amap.model;

import androidx.annotation.Nullable;

import java.util.Map;

public class HeyhipMarkerIconModel {

    public final String type;
    public final Object value;
    public final int width;
    public final int height;

    private HeyhipMarkerIconModel(
            String type,
            Object value,
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
    public static HeyhipMarkerIconModel fromMap(Map<String, Object> map) {
        if (map == null) return null;

        Object iconObj = map.get("icon");
        if (!(iconObj instanceof Map)) return null;

        Map<String, Object> icon = (Map<String, Object>) iconObj;

        String type = icon.get("type") instanceof String
                ? (String) icon.get("type")
                : null;

        if (type == null) return null;

        Object value = icon.get("value");

        int width = map.get("iconWidth") instanceof Number
                ? ((Number) map.get("iconWidth")).intValue()
                : 48;

        int height = map.get("iconHeight") instanceof Number
                ? ((Number) map.get("iconHeight")).intValue()
                : 48;

        return new HeyhipMarkerIconModel(type, value, width, height);
    }
}
