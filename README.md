# heyhip_amap

## 0.0.3
- Minor fixes and improvements.

一个基于 **Flutter Plugin** 的高德地图插件，支持 Android / iOS，面向真实业务场景封装。
 
---
 
## 功能特性 
 
- ✅ 跨平台支持：Android / iOS 原生高德地图集成 
- 🗺️ 核心功能：
  - 地图展示 & 相机控制
  - Marker 添加与点击交互
  - Marker InfoWindow（气泡，可开关）
  - Marker 聚合（Cluster）
- 🔍 搜索能力：
  - 周边 POI 搜索（经纬度）
  - 关键字 POI 搜索（文本搜索）
  - 搜索结果字段对齐（Android/iOS 统一 distance/type 字段）
  - 支持分页查询 
- ⚡ 优化特性：
  - 地图未 ready 时操作自动缓存 
 
---
 
## 快速开始 
 
### 初始化配置 
```dart 
// 设置高德Key 
HeyhipAmap.initKey(
  androidKey: "YOUR_ANDROID_KEY", 
  iosKey: "YOUR_IOS_KEY"
);
 
// 隐私合规设置 
HeyhipAmap.updatePrivacy(
  hasAgree: true, 
  hasShow: true, 
  hasContains: true
);


Platform Configuration
Android
在 AndroidManifest.xml 中添加以下权限

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>


高德 Key 配置

<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_AMAP_KEY"/>


iOS
Info.plist 配置高德 Key
<key>AMapApiKey</key>
<string>YOUR_AMAP_KEY</string>

ios/Podfile文件添加如下
target 'Runner' do
  # use_frameworks!

  # 添加静态
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

Basic Usage
创建 Controller

final controller = HeyhipAmapController();


HeyhipAmapView(
  latitude: 31.2304,
  longitude: 121.4737,
  zoom: 14,
  controller: controller,
  clusterEnabled: true,
  enableMarkerPopup: true,
)

controller.moveCamera(
  CameraPosition(
    target: LatLng(31.2304, 121.4737),
    zoom: 16,
  ),
);


controller.setMarkers([
  HeyhipMarker(
    id: '1',
    latitude: 31.2304,
    longitude: 121.4737,
    title: 'Marker Title',
    snippet: 'Marker Description',
  ),
]);


controller.searchPoisByLatLng(
  LatLng(31.2304, 121.4737),
  radius: 1000,
  page: 1,
  pageSize: 20,
);


controller.searchPoisByText(
  '咖啡',
  city: '上海',
  page: 1,
  pageSize: 20,
);
```


