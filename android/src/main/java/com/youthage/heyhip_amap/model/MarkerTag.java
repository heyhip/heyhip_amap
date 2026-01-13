package com.youthage.heyhip_amap.model;

import java.util.Map;

public class MarkerTag {
    public final String id;
    public final HeyhipMarkerPopupModel popup;

    public MarkerTag(String id, HeyhipMarkerPopupModel popup) {
        this.id = id;
        this.popup = popup;
    }
}
