package com.youthage.heyhip_amap.model;

import com.amap.api.maps.model.LatLng;

import java.util.Map;

public class HeyhipMarkerModel {

    public final String id;
    public final LatLng latLng;
    public final HeyhipMarkerIcon icon;

    // ⭐ 新增：popup
    public final HeyhipMarkerPopup popup;

    private HeyhipMarkerModel(
            String id,
            LatLng latLng,
            HeyhipMarkerIcon icon,
            HeyhipMarkerPopup popup
    ) {
        this.id = id;
        this.latLng = latLng;
        this.icon = icon;
        this.popup = popup;
    }

    @SuppressWarnings("unchecked")
    public static HeyhipMarkerModel fromMap(Map<String, Object> map) {

        Object idObj = map.get("id");
        Object latObj = map.get("latitude");
        Object lngObj = map.get("longitude");

        if (!(idObj instanceof String)
                || !(latObj instanceof Number)
                || !(lngObj instanceof Number)) {
            return null;
        }

        String id = (String) idObj;
        double lat = ((Number) latObj).doubleValue();
        double lng = ((Number) lngObj).doubleValue();

        // icon
        HeyhipMarkerIcon icon =
                HeyhipMarkerIcon.fromMap(map.get("icon"));

        // ⭐ popup
        HeyhipMarkerPopup popup =
                HeyhipMarkerPopup.fromMap(map.get("popup"));

        return new HeyhipMarkerModel(
                id,
                new LatLng(lat, lng),
                icon,
                popup
        );
    }
}
