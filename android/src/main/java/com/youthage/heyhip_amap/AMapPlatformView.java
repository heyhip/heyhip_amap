package com.youthage.heyhip_amap;

import android.content.Context;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Point;
import android.graphics.drawable.Drawable;
import android.util.Base64;
import android.util.Log;
import android.util.LruCache;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.UiSettings;
import com.amap.api.maps.model.BitmapDescriptor;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.CameraPosition;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.LatLngBounds;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.MarkerOptions;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;


import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;

import android.animation.ValueAnimator;
import android.view.animation.DecelerateInterpolator;


public class AMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler {

    private final int viewId;
    private final MapView mapView;
    private final AMap aMap;
    private MethodChannel channel;
    // 是否启用聚合
    private boolean clusterEnabled = false;

    // 聚合样式
    @Nullable
    private Map<String, Object> clusterStyle;


    // 初始定位
    private Double initLatitude;
    private Double initLongitude;
    private Float initZoom;

    // 初始化地图类型
    private Integer initMapType;

    // 持续移动节流
    private static final long CAMERA_MOVE_THROTTLE_MS = 120;
    private long lastCameraMoveTime = 0;

    // 自定义，用于有开始移动功能
    private boolean isCameraMoving = false;

    // 单点 marker（真实数据）
    private final Map<String, Marker> itemMarkers = new HashMap<>();

    // 聚合 marker
    private final Map<String, Marker> clusterMarkers = new HashMap<>();

    // 最近一次 Flutter 传下来的 markers（用于自动聚合）
    private List<Map<String, Object>> lastMarkers;

    // 最后可视区域
    private LatLngBounds lastVisibleBounds;

    // 上一次聚合参数
    private int lastZoomLevel = -1;
    private int lastGridSize = -1;


    // 地图是否加载完成
    private boolean mapReady = false;


    // Marker icon 内存缓存（url + size → Bitmap）
    private static final LruCache<String, Bitmap> iconCache;

    static {
        int maxMemory = (int) (Runtime.getRuntime().maxMemory() / 1024);
        int cacheSize = maxMemory / 16; // 使用 1/16 内存

        iconCache = new LruCache<String, Bitmap>(cacheSize) {
            @Override
            protected int sizeOf(String key, Bitmap value) {
                return value.getByteCount() / 1024;
            }
        };
    }


    public AMapPlatformView(Context context, int id, Map<String, Object> params) {
        this.viewId = id;

        // 1️⃣ 创建 MapView
        mapView = new MapView(context);
        mapView.onCreate(null);

        // 2️⃣ 获取 AMap 实例
        aMap = mapView.getMap();

        // 监听地图完成
        aMap.setOnMapLoadedListener(new AMap.OnMapLoadedListener() {
            @Override
            public void onMapLoaded() {
                mapReady = true;

                // 地图类型
                if (initMapType != null) {
                    applyMapType(initMapType);
                }

                // ui设置
                applyUiSettings(params);

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

        // 监听地图点击
        aMap.setOnMapClickListener(new AMap.OnMapClickListener() {
            @Override
            public void onMapClick(LatLng latLng) {
                notifyMapClick(latLng);
            }
        });

        // 监听地图移动
        aMap.setOnCameraChangeListener(new AMap.OnCameraChangeListener() {

            @Override
            public void onCameraChange(CameraPosition cameraPosition) {

                // ⭐ 第一次进入 = 开始移动
                if (!isCameraMoving) {
                    isCameraMoving = true;
                    notifyCameraMoveStart(cameraPosition);
                }

                // ⭐ 地图正在拖动 / 缩放 / 旋转
                notifyCameraMoving(cameraPosition); // 持续（已节流）
            }

            @Override
            public void onCameraChangeFinish(CameraPosition cameraPosition) {
                isCameraMoving = false;

                // 可选：如果你将来要“结束回调”
                notifyCameraIdle(cameraPosition); // 完成（不节流）
            }
        });

        // 监听marker点击
        aMap.setOnMarkerClickListener(marker -> {

            Object tag = marker.getObject();

            // =========================
            // 1️⃣ 点击的是「聚合点」
            // =========================
            if (tag instanceof ClusterTag) {
                ClusterTag clusterTag = (ClusterTag) tag;
                onClusterClick(clusterTag.cluster);
                return true;
            }

            // =========================
            // 2️⃣ 点击的是「单点 marker」
            // =========================
            if (tag instanceof String) {

                String markerId = (String) tag;
                LatLng position = marker.getPosition();

                if (channel != null) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("markerId", markerId);
                    map.put("latitude", position.latitude);
                    map.put("longitude", position.longitude);

                    channel.invokeMethod("onMarkerClick", map);
                }

                return true;
            }

            return true;
        });


        if (params != null) {

            // 初始定位
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

            // 地图类型
            Object type = params.get("mapType");
            if (type instanceof Number) {
                initMapType = ((Number) type).intValue();
            }
            
            // =========================
            // 是否启用聚合
            // =========================
            Object ce = params.get("clusterEnabled");
            if (ce instanceof Boolean) {
                clusterEnabled = (Boolean) ce;
            }

            // =========================
            // 聚合样式
            // =========================
            Object cs = params.get("clusterStyle");
            if (cs instanceof Map) {
                clusterStyle = (Map<String, Object>) cs;
            }


        }


        // 4️⃣ 绑定 MethodChannel（重点）
        channel = new MethodChannel(
                HeyhipAmapPlugin.getMessenger(),
                "heyhip_amap_map_" + id
        );
        channel.setMethodCallHandler(this);

        // ⭐ 注册 MapView
        HeyhipAmapPlugin.MAP_VIEWS.put(id, this);
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        channel.setMethodCallHandler(null);
        onDestroy();

        // ⭐ 从注册表移除
        HeyhipAmapPlugin.MAP_VIEWS.remove(viewId);
    }

    void onResume() {
        if (mapView != null) mapView.onResume();
    }

    void onPause() {
        if (mapView != null) mapView.onPause();
    }

    void onDestroy() {
        if (mapView != null) mapView.onDestroy();
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

    private int getInt(Object value, int def) {
        return value instanceof Number ? ((Number) value).intValue() : def;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "setMarkers":
                handleSetMarkers(call, result);
                break;
            case "moveCamera":
                moveCamera(call, result);
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

    // ui设置
    private void applyUiSettings(Map<String, Object> params) {
        if (params == null) return;

        Object uiObj = params.get("uiSettings");
        if (!(uiObj instanceof Map)) return;

        Map<String, Object> ui = (Map<String, Object>) uiObj;
        UiSettings uiSettings = aMap.getUiSettings();

        Boolean zoomControls = (Boolean) ui.get("zoomControlsEnabled");
        if (zoomControls != null) {
            uiSettings.setZoomControlsEnabled(zoomControls);
        }

        Boolean compass = (Boolean) ui.get("compassEnabled");
        if (compass != null) {
            uiSettings.setCompassEnabled(compass);
        }

        Boolean scale = (Boolean) ui.get("scaleControlsEnabled");
        if (scale != null) {
            uiSettings.setScaleControlsEnabled(scale);
        }

        Boolean myLocation = (Boolean) ui.get("myLocationButtonEnabled");
        if (myLocation != null) {
            uiSettings.setMyLocationButtonEnabled(myLocation);
        }

        Boolean rotate = (Boolean) ui.get("rotateGesturesEnabled");
        if (rotate != null) {
            uiSettings.setRotateGesturesEnabled(rotate);
        }

        Boolean tilt = (Boolean) ui.get("tiltGesturesEnabled");
        if (tilt != null) {
            uiSettings.setTiltGesturesEnabled(tilt);
        }

        Boolean zoomGesture = (Boolean) ui.get("zoomGesturesEnabled");
        if (zoomGesture != null) {
            uiSettings.setZoomGesturesEnabled(zoomGesture);
        }
    }

    // 地图类型
    private void applyMapType(int type) {
        switch (type) {
            case 1:
                aMap.setMapType(AMap.MAP_TYPE_SATELLITE);
                break;

            case 2:
                aMap.setMapType(AMap.MAP_TYPE_NIGHT);
                break;

            case 3:
                aMap.setMapType(AMap.MAP_TYPE_NAVI);
                break;

            case 4:
                aMap.setMapType(AMap.MAP_TYPE_BUS);
                break;

            case 0:
            default:
                aMap.setMapType(AMap.MAP_TYPE_NORMAL);
                break;
        }
    }

    // icon
    private BitmapDescriptor buildMarkerIcon(Map<String, Object> item) {
        Object iconObj = item.get("icon");
        if (!(iconObj instanceof Map)) {
            return BitmapDescriptorFactory.defaultMarker();
        }

        Map<String, Object> icon = (Map<String, Object>) iconObj;
        String type = (String) icon.get("type");
        Object value = icon.get("value");

        int width = getInt(item.get("iconWidth"), 48);
        int height = getInt(item.get("iconHeight"), 48);

        try {
            switch (type) {
                case "asset":
                    return loadFromAsset((String) value, width, height);

                case "bitmap":
                    return loadFromBitmap(value, width, height);

                case "base64":
                    return loadFromBase64((String) value, width, height);

                case "network":
                    // ⭐ 网络图：这里只返回占位 icon
                    return BitmapDescriptorFactory.defaultMarker();

                default:
                    return BitmapDescriptorFactory.defaultMarker();
            }
        } catch (Exception e) {
            return BitmapDescriptorFactory.defaultMarker();
        }
    }


    // icon聚合
    private BitmapDescriptor buildClusterIcon(int count) {

        // =========================
        // 1️⃣ 默认样式（兜底）
        // =========================
        int bgColor = 0xFF3F51B5;      // 默认蓝色
        int textColor = 0xFFFFFFFF;   // 默认白字
        boolean strokeEnabled = true;
        int strokeColor = 0xFFFFFFFF;

        // =========================
        // 2️⃣ Flutter 传入样式覆盖
        // 仅在 clusterEnabled == true 时生效
        // =========================
        if (clusterEnabled && clusterStyle != null) {

            Object bg = clusterStyle.get("bgColor");
            Object tc = clusterStyle.get("textColor");
            Object ss = clusterStyle.get("showStroke");
            Object sc = clusterStyle.get("strokeColor");

            if (bg instanceof Number) {
                bgColor = ((Number) bg).intValue();
            }

            if (tc instanceof Number) {
                textColor = ((Number) tc).intValue();
            }

            if (ss instanceof Boolean) {
                strokeEnabled = (Boolean) ss;
            }

            if (sc instanceof Number) {
                strokeColor = ((Number) sc).intValue();
            }
        }

        // =========================
        // 3️⃣ 根据数量决定尺寸
        // =========================
        int sizeDp;
        if (count < 10) {
            sizeDp = 40;
        } else if (count < 100) {
            sizeDp = 48;
        } else {
            sizeDp = 56;
        }

        float density = mapView.getResources().getDisplayMetrics().density;
        int sizePx = (int) (sizeDp * density);

        // =========================
        // 4️⃣ 创建 Bitmap + Canvas
        // =========================
        Bitmap bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);

        // =========================
        // 5️⃣ 背景圆
        // =========================
        Paint circlePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        circlePaint.setColor(bgColor);

        canvas.drawCircle(
                sizePx / 2f,
                sizePx / 2f,
                sizePx / 2f,
                circlePaint
        );

        // =========================
        // 6️⃣ 描边（可选）
        // =========================
        if (strokeEnabled) {
            Paint strokePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
            strokePaint.setStyle(Paint.Style.STROKE);
            strokePaint.setStrokeWidth(2 * density);
            strokePaint.setColor(strokeColor);

            canvas.drawCircle(
                    sizePx / 2f,
                    sizePx / 2f,
                    sizePx / 2f - strokePaint.getStrokeWidth() / 2,
                    strokePaint
            );
        }

        // =========================
        // 7️⃣ 数字
        // =========================
        Paint textPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        textPaint.setColor(textColor);
        textPaint.setTextAlign(Paint.Align.CENTER);
        textPaint.setFakeBoldText(true);

        if (count < 10) {
            textPaint.setTextSize(16 * density);
        } else if (count < 100) {
            textPaint.setTextSize(15 * density);
        } else {
            textPaint.setTextSize(14 * density);
        }

        String text = String.valueOf(count);
        Paint.FontMetrics fm = textPaint.getFontMetrics();
        float textY = sizePx / 2f - (fm.ascent + fm.descent) / 2;

        canvas.drawText(
                text,
                sizePx / 2f,
                textY,
                textPaint
        );

        return BitmapDescriptorFactory.fromBitmap(bitmap);
    }





    private BitmapDescriptor loadFromAsset(
            String assetPath,
            int width,
            int height
    ) throws IOException {

        AssetManager am = mapView.getContext().getAssets();
        InputStream is = am.open(assetPath);
        Bitmap bitmap = BitmapFactory.decodeStream(is);

        Bitmap scaled = Bitmap.createScaledBitmap(bitmap, width, height, true);
        return BitmapDescriptorFactory.fromBitmap(scaled);
    }

    private BitmapDescriptor loadFromBitmap(
            Object value,
            int width,
            int height
    ) {
        if (!(value instanceof byte[])) {
            return BitmapDescriptorFactory.defaultMarker();
        }

        byte[] bytes = (byte[]) value;
        Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        Bitmap scaled = Bitmap.createScaledBitmap(bitmap, width, height, true);
        return BitmapDescriptorFactory.fromBitmap(scaled);
    }

    private BitmapDescriptor loadFromBase64(
            String base64,
            int width,
            int height
    ) {
        byte[] bytes = Base64.decode(base64, Base64.DEFAULT);
        Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        Bitmap scaled = Bitmap.createScaledBitmap(bitmap, width, height, true);
        return BitmapDescriptorFactory.fromBitmap(scaled);
    }

    private void loadFromNetwork(
            String url,
            int width,
            int height,
            final Marker marker
    ) {
        if (url == null || url.isEmpty() || marker == null) return;

        final String cacheKey = url + "_" + width + "x" + height;

        // 1️⃣ 内存缓存
        Bitmap cached = iconCache.get(cacheKey);
        if (cached != null && !cached.isRecycled()) {
            marker.setIcon(BitmapDescriptorFactory.fromBitmap(cached));
            return;
        }

        // 2️⃣ Glide 异步加载
        Glide.with(mapView.getContext())
                .asBitmap()
                .load(url)
                .override(width, height)
                .centerCrop()
                .into(new CustomTarget<Bitmap>() {

                    @Override
                    public void onResourceReady(
                            @NonNull Bitmap bitmap,
                            @Nullable Transition<? super Bitmap> transition
                    ) {
                        if (bitmap.isRecycled()) return;

                        iconCache.put(cacheKey, bitmap);

                        try {
                            marker.setIcon(
                                    BitmapDescriptorFactory.fromBitmap(bitmap)
                            );
                        } catch (Exception ignore) {
                            // marker 已被 remove（diff 场景）
                        }
                    }

                    @Override
                    public void onLoadCleared(@Nullable Drawable placeholder) {}

                    @Override
                    public void onLoadFailed(@Nullable Drawable errorDrawable) {}
                });
    }


    // 移动地图
    private void moveCamera(MethodCall call, MethodChannel.Result result) {

        Map<String, Object> target = call.argument("target");
        if (target == null) {
            result.error("INVALID_PARAM", "target is null", null);
            return;
        }

        Double lat = (Double) target.get("latitude");
        Double lng = (Double) target.get("longitude");
        Double zoom = call.argument("zoom");
        Double tilt = call.argument("tilt");
        Double bearing = call.argument("bearing");

        if (lat == null || lng == null) {
            result.error("INVALID_PARAM", "lat or lng is null", null);
            return;
        }

        CameraPosition current = aMap.getCameraPosition();

        CameraPosition position = new CameraPosition(
                new LatLng(lat, lng),
                zoom != null ? zoom.floatValue() : current.zoom,
                tilt != null ? tilt.floatValue() : current.tilt,
                bearing != null ? bearing.floatValue() : current.bearing
        );


        aMap.animateCamera(CameraUpdateFactory.newCameraPosition(position));
        result.success(null);
    }

    // 设置Marker
    private void handleSetMarkers(MethodCall call, MethodChannel.Result result) {
        if (!mapReady) {
            result.error("MAP_NOT_READY", "Map is not loaded yet", null);
            return;
        }

        Object listObj = call.argument("markers");
        if (!(listObj instanceof List)) {
            result.error("INVALID_PARAM", "markers is not a list", null);
            return;
        }

        List<Map<String, Object>> list = (List<Map<String, Object>>) listObj;

        // ⭐ Step 4-6.1：缓存 markers
        lastMarkers = list;

        // ⭐ Step 4-6.2：真正刷新聚合
        refreshClusters(list);

        result.success(null);
    }


    // 刷新聚合
    private void refreshClusters(List<Map<String, Object>> list) {
        if (!mapReady || list == null || aMap == null) return;

        float zoom = aMap.getCameraPosition().zoom;
        int zoomLevel = Math.round(zoom);
        // int gridSize = getClusterGridSize(zoom);
        int gridSize = clusterEnabled ? getClusterGridSize(zoom) : 0; // 0 = 不聚合


        boolean sameZoom = zoomLevel == lastZoomLevel;
        boolean sameGrid = gridSize == lastGridSize;
        LatLngBounds currentBounds = getVisibleBounds();

        // boolean sameBounds = isSameBounds(lastVisibleBounds, currentBounds);

        if (sameZoom && sameGrid && isSameBounds(lastVisibleBounds, currentBounds) && lastMarkers == list) {
            return;
        }

        // =====================================================
        // 构造「可视区域内」的 ClusterItem
        // =====================================================
        List<ClusterItem> visibleItems = new ArrayList<>();

        for (Map<String, Object> item : list) {
            Object idObj = item.get("id");
            Object latObj = item.get("latitude");
            Object lngObj = item.get("longitude");

            if (!(idObj instanceof String)
                    || !(latObj instanceof Number)
                    || !(lngObj instanceof Number)) {
                continue;
            }

            LatLng latLng = new LatLng(
                    ((Number) latObj).doubleValue(),
                    ((Number) lngObj).doubleValue()
            );

            if (!isInVisibleBounds(latLng)) continue;

            visibleItems.add(
                    new ClusterItem((String) idObj, latLng)
            );
        }

        // =====================================================
        // Step 4-5-3：生成 clusters
        // =====================================================
        List<Cluster> clusters;

        if (gridSize == 0) {
            clusters = new ArrayList<>();
            for (ClusterItem item : visibleItems) {
                Cluster c = new Cluster();
                c.items.add(item);
                c.center = item.latLng;
                clusters.add(c);
            }
        } else {
            clusters = buildClusters(visibleItems, gridSize, zoomLevel);
        }

        // =====================================================
        // Step 4-5-4：本轮 marker key
        // =====================================================
        Set<String> newMarkerKeys = new HashSet<>();

        // =====================================================
        // Step 4-5-5：渲染 clusters
        // =====================================================
        for (Cluster cluster : clusters) {

            // ---------- 单点 ----------
            if (cluster.items.size() == 1) {

                ClusterItem item = cluster.items.get(0);
                String markerKey = item.id;
                newMarkerKeys.add(markerKey);

                Marker marker = itemMarkers.get(markerKey);

                if (marker == null) {
                    marker = aMap.addMarker(
                            new MarkerOptions()
                                    .position(item.latLng)
                                    .icon(findItemIcon(list, item.id))
                    );
                    marker.setObject(markerKey);
                    itemMarkers.put(markerKey, marker);

                    // ⭐ 新增：出现动画
                    animateMarkerAppear(marker);
                } else {
                    marker.setPosition(item.latLng);
                }

                // network icon
                Map<String, Object> src = findItem(list, item.id);
                if (src != null) {
                    Object iconObj = src.get("icon");
                    if (iconObj instanceof Map) {
                        
                        Map<String, Object> icon = (Map<String, Object>) iconObj;
                        if ("network".equals(icon.get("type"))) {
                            String url = (String) icon.get("value");
                            int w = getInt(src.get("iconWidth"), 48);
                            int h = getInt(src.get("iconHeight"), 48);
                            loadFromNetwork(url, w, h, marker);
                        }
                    }
                }

            }
            // ---------- 聚合 ----------
            else {

                Point p = latLngToWorldPoint(cluster.center, zoomLevel);

                String markerKey = buildClusterId(p, gridSize, zoomLevel);
                newMarkerKeys.add(markerKey);

                Marker marker = clusterMarkers.get(markerKey);

                if (marker == null) {
                    marker = aMap.addMarker(
                            new MarkerOptions()
                                    .position(cluster.center)
                                    .icon(buildClusterIcon(cluster.items.size()))
                    );

                    ClusterTag tag = new ClusterTag();
                    tag.cluster = cluster;
                    tag.count = cluster.items.size();

                    marker.setObject(tag);
                    clusterMarkers.put(markerKey, marker);

                    animateMarkerAppear(marker);

                } else {
                    marker.setPosition(cluster.center);

                    ClusterTag tag = (ClusterTag) marker.getObject();
                    tag.cluster = cluster;

                    int newCount = cluster.items.size();
                    if (tag.count != newCount) {
                        marker.setIcon(buildClusterIcon(newCount));
                        tag.count = newCount;
                    }
                }
            }


        }


        // =====================================================
        // Step 4-5-6：diff 删除旧 marker
        // =====================================================
        Iterator<Map.Entry<String, Marker>> it1 = itemMarkers.entrySet().iterator();
        while (it1.hasNext()) {
            Map.Entry<String, Marker> entry = it1.next();
            if (!newMarkerKeys.contains(entry.getKey())) {
                Marker m = entry.getValue();
                it1.remove();

                // ⭐ 改为动画删除
                animateMarkerDisappear(m, null);

            }
        }

        Iterator<Map.Entry<String, Marker>> it2 = clusterMarkers.entrySet().iterator();
        while (it2.hasNext()) {
            Map.Entry<String, Marker> entry = it2.next();
            if (!newMarkerKeys.contains(entry.getKey())) {
                Marker m = entry.getValue();
                it2.remove();

                // ⭐ 改为动画删除
                animateMarkerDisappear(m, null);

            }
        }

        // ===== Step 4-8.4：更新缓存 =====
        lastZoomLevel = zoomLevel;
        lastGridSize = gridSize;
        lastVisibleBounds = currentBounds;

    }





    @Nullable
    private Map<String, Object> findItem(
            List<Map<String, Object>> list,
            String id
    ) {
        for (Map<String, Object> item : list) {
            if (id.equals(item.get("id"))) {
                return item;
            }
        }
        return null;
    }

    private BitmapDescriptor findItemIcon(
            List<Map<String, Object>> list,
            String id
    ) {
        Map<String, Object> item = findItem(list, id);
        return item != null
                ? buildMarkerIcon(item)
                : BitmapDescriptorFactory.defaultMarker();
    }

    // 转世界坐标
    private Point latLngToWorldPoint(LatLng latLng, int zoomLevel) {
        double siny = Math.sin(latLng.latitude * Math.PI / 180);
        siny = Math.min(Math.max(siny, -0.9999), 0.9999);

        double x = 256 * (0.5 + latLng.longitude / 360);
        double y = 256 * (0.5 - Math.log((1 + siny) / (1 - siny)) / (4 * Math.PI));

        double scale = Math.pow(2, zoomLevel);

        return new Point(
                (int) (x * scale),
                (int) (y * scale)
        );
    }


    // 是否在可视范围内
    private boolean isSameBounds(
            @Nullable LatLngBounds a,
            @Nullable LatLngBounds b
    ) {
        if (a == null || b == null) return false;

        final double eps = 1e-6;

        return Math.abs(a.southwest.latitude - b.southwest.latitude) < eps
                && Math.abs(a.southwest.longitude - b.southwest.longitude) < eps
                && Math.abs(a.northeast.latitude - b.northeast.latitude) < eps
                && Math.abs(a.northeast.longitude - b.northeast.longitude) < eps;
    }

    // 获取可视边界
    private LatLngBounds getVisibleBounds() {
        if (aMap == null) return null;
        return aMap.getProjection().getVisibleRegion().latLngBounds;
    }

    // 是否在可视边界内
    private boolean isInVisibleBounds(LatLng latLng) {
        if (aMap == null) return false;

        LatLngBounds bounds =
                aMap.getProjection().getVisibleRegion().latLngBounds;

        return bounds.contains(latLng);
    }

    // 经纬度 → 屏幕像素
    // private Point latLngToPoint(LatLng latLng) {
    //     return aMap.getProjection().toScreenLocation(latLng);
    // }


    // 聚合
    private int getClusterGridSize(float zoom) {
        if (zoom < 5)  return 200;
        if (zoom < 8)  return 120;
        if (zoom < 11) return 80;
        if (zoom < 14) return 60;
        if (zoom < 17) return 40;
        return 0; // 0 = 不聚合
    }

    // 生成聚合唯一的key
    private String buildClusterId(Point p, int gridSizePx, int zoomLevel) {
        if (gridSizePx <= 0) {
            return "single_" + zoomLevel + "_" + p.x + "_" + p.y;
        }
        int gx = p.x / gridSizePx;
        int gy = p.y / gridSizePx;
        return "cluster_" + zoomLevel + "_" + gx + "_" + gy;
    }


    // 获取当前层级
    private int getZoomLevel() {
        return Math.round(aMap.getCameraPosition().zoom);
    }

    // 聚合算法
    private List<Cluster> buildClusters(
            List<ClusterItem> items,
            int gridSizePx,
            int zoomLevel
    ) {
        List<Cluster> clusters = new ArrayList<>();

        // ===== 不聚合：每个点一个 cluster =====
        if (gridSizePx <= 0) {
            for (ClusterItem item : items) {
                Cluster c = new Cluster();
                c.items.add(item);
                c.center = item.latLng;
                clusters.add(c);
            }
            return clusters;
        }

        // ===== 聚合逻辑 =====
        Map<String, Cluster> gridMap = new HashMap<>();

        for (ClusterItem item : items) {

            // 经纬度 → 世界坐标（跟 zoom 绑定）
            Point p = latLngToWorldPoint(item.latLng, zoomLevel);

            int gx = p.x / gridSizePx;
            int gy = p.y / gridSizePx;

            String key = gx + "_" + gy;

            Cluster cluster = gridMap.get(key);
            if (cluster == null) {
                cluster = new Cluster();
                gridMap.put(key, cluster);
                clusters.add(cluster);
            }

            cluster.items.add(item);
        }

        // ===== 计算每个 cluster 的中心点 =====
        for (Cluster cluster : clusters) {
            double lat = 0;
            double lng = 0;

            for (ClusterItem item : cluster.items) {
                lat += item.latLng.latitude;
                lng += item.latLng.longitude;
            }

            int size = cluster.items.size();
            cluster.center = new LatLng(lat / size, lng / size);
        }

        return clusters;
    }


    // 点击聚合
    private void onClusterClick(Cluster cluster) {
        if (cluster == null || cluster.items == null || cluster.items.isEmpty()) {
            return;
        }

        // 当前相机信息
        CameraPosition camera = aMap.getCameraPosition();
        float currentZoom = camera.zoom;
        float maxZoom = aMap.getMaxZoomLevel();

        // =========================
        // ⭐ 智能 zoom 步进策略
        // =========================
        float step;
        if (currentZoom < 8f) {
            step = 2.5f;      // 世界级 / 国家级
        } else if (currentZoom < 12f) {
            step = 2.0f;      // 城市级
        } else if (currentZoom < 15f) {
            step = 1.5f;      // 街道级
        } else {
            step = 1.0f;      // 细节级
        }

        float targetZoom = Math.min(currentZoom + step, maxZoom);

        // =========================
        // ⭐ 轻微偏移：让展开更自然
        // =========================
        LatLng center = cluster.center;

        // =========================
        // ⭐ 平滑动画（带回调）
        // =========================
        aMap.animateCamera(
                CameraUpdateFactory.newCameraPosition(
                        new CameraPosition(
                                center,
                                targetZoom,
                                camera.tilt,
                                camera.bearing
                        )
                ),
                350,
                null
        );
    }


    // marker出现动画
    private void animateMarkerAppear(final Marker marker) {
        if (marker == null) return;

        marker.setAlpha(0f);

        ValueAnimator animator = ValueAnimator.ofFloat(0f, 1f);
        animator.setDuration(220);
        animator.setInterpolator(new DecelerateInterpolator());

        animator.addUpdateListener(animation -> {
            float v = (float) animation.getAnimatedValue();

            // alpha
            marker.setAlpha(v);

            // scale（通过 anchor + 假 scale）
            marker.setAnchor(0.5f, 0.5f);
            marker.setZIndex(v);
        });

        animator.start();
    }

    // marker消失动画
    private void animateMarkerDisappear(
            final Marker marker,
            final Runnable onEnd
    ) {
        if (marker == null) {
            if (onEnd != null) onEnd.run();
            return;
        }

        ValueAnimator animator = ValueAnimator.ofFloat(1f, 0f);
        animator.setDuration(180);
        animator.setInterpolator(new DecelerateInterpolator());

        animator.addUpdateListener(animation -> {
            float v = (float) animation.getAnimatedValue();
            marker.setAlpha(v);
        });

        animator.addListener(new android.animation.AnimatorListenerAdapter() {
            @Override
            public void onAnimationEnd(android.animation.Animator animation) {
                try {
                    marker.remove();
                } catch (Exception ignored) {}
                if (onEnd != null) onEnd.run();
            }
        });

        animator.start();
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

    // 发送地图加载完成消息
    private void notifyMapLoaded() {
        if (channel == null) return;

        channel.invokeMethod("onMapLoaded", null);
    }

    // 发送地图点击消息
    private void notifyMapClick(LatLng latLng) {
        if (channel == null) return;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", latLng.latitude);
        map.put("longitude", latLng.longitude);

        channel.invokeMethod("onMapClick", map);
    }

    // 开始移动
    private void notifyCameraMoveStart(CameraPosition position) {
        if (channel == null) return;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        channel.invokeMethod("onCameraMoveStart", map);
    }

    // 发送持续移动位置
    private void notifyCameraMoving(CameraPosition position) {
        if (channel == null) return;

        long now = System.currentTimeMillis();
        if (now - lastCameraMoveTime < CAMERA_MOVE_THROTTLE_MS) {
            return;
        }

        lastCameraMoveTime = now;

        Map<String, Object> map = new HashMap<>();
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        channel.invokeMethod("onCameraMove", map);
    }

    // 发送移动完成中心点消息
    private void notifyCameraIdle(CameraPosition position) {
        if (channel == null || aMap == null) return;

        LatLngBounds bounds = getVisibleBounds();
        if (bounds == null) return;

        Map<String, Object> map = new HashMap<>();

        // 中心 & 相机
        map.put("latitude", position.target.latitude);
        map.put("longitude", position.target.longitude);
        map.put("zoom", position.zoom);
        map.put("tilt", position.tilt);
        map.put("bearing", position.bearing);

        // 可视区域（给后面聚合用）
        Map<String, Object> visible = new HashMap<>();
        visible.put("southWestLat", bounds.southwest.latitude);
        visible.put("southWestLng", bounds.southwest.longitude);
        visible.put("northEastLat", bounds.northeast.latitude);
        visible.put("northEastLng", bounds.northeast.longitude);

        map.put("visibleBounds", visible);

        channel.invokeMethod("onCameraIdle", map);

        // ⭐ 自动刷新聚合（关键）
        if (lastMarkers != null) {
            refreshClusters(lastMarkers);
        }

    }



    // 聚合使用
    private static class ClusterItem {
        final String id;
        final LatLng latLng;

        ClusterItem(String id, LatLng latLng) {
            this.id = id;
            this.latLng = latLng;
        }
    }

    private static class Cluster {
        final List<ClusterItem> items = new ArrayList<>();
        LatLng center;
    }

    static class ClusterTag {
        Cluster cluster;
        int count;
    }


}



