package com.youthage.heyhip_amap.model;

import java.util.Map;

public class HeyhipMarkerPopupModel {

    public final String title;
    public final String subtitle;
    public final String avatar; // url / asset key / base64（你后面定）
    public final String avatarUrl;

    private HeyhipMarkerPopupModel(
            String title,
            String subtitle,
            String avatar,
            String avatarUrl
    ) {
        this.title = title;
        this.subtitle = subtitle;
        this.avatar = avatar;
        this.avatarUrl = avatarUrl;
    }

    @SuppressWarnings("unchecked")
    public static HeyhipMarkerPopupModel fromMap(Object obj) {

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

        String avatarUrl = map.get("avatarUrl") instanceof String
                ? (String) map.get("avatarUrl")
                : null;

        // 至少有一个字段才认为 popup 有效
        if (title == null && subtitle == null && avatar == null) {
            return null;
        }

        return new HeyhipMarkerPopupModel(
                title,
                subtitle,
                avatar,
                avatarUrl
        );
    }
}
