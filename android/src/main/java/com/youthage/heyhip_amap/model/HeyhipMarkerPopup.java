package com.youthage.heyhip_amap.model;

import java.util.Map;

public class HeyhipMarkerPopup {

    public final String title;
    public final String subtitle;
    public final String avatar;

    private HeyhipMarkerPopup(
            String title,
            String subtitle,
            String avatar
    ) {
        this.title = title;
        this.subtitle = subtitle;
        this.avatar = avatar;
    }

    @SuppressWarnings("unchecked")
    public static HeyhipMarkerPopup fromMap(Object obj) {

        if (!(obj instanceof Map)) return null;

        Map<String, Object> map = (Map<String, Object>) obj;

        String title = map.get("title") instanceof String
                ? (String) map.get("title")
                : null;

        String subtitle = map.get("subtitle") instanceof String
                ? (String) map.get("subtitle")
                : null;

        String avatar = map.get("avatar") instanceof String
                ? (String) map.get("avatar")
                : null;

        // 至少有一个字段才认为 popup 有效
        if (title == null && subtitle == null && avatar == null) {
            return null;
        }

        return new HeyhipMarkerPopup(
                title,
                subtitle,
                avatar
        );
    }
}
