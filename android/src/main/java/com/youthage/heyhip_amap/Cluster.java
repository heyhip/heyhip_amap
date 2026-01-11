package com.youthage.heyhip_amap;

import com.amap.api.maps.model.LatLng;

import java.util.List;

public class Cluster {
    public String id;              // ⭐ 稳定 ID（核心）
    public LatLng center;           // 聚合中心点
    public List<LatLng> items;      // 聚合内的点
    public int count;               // items.size()
}
