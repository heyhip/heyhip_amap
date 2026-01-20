import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:heyhip_amap/amap_ui_settings.dart';
import 'package:heyhip_amap/camera_position.dart';
import 'package:heyhip_amap/cluster_style.dart';
import 'package:heyhip_amap/heyhip_amap.dart';
import 'package:heyhip_amap/heyhip_amap_controller.dart';
import 'package:heyhip_amap/heyhip_marker.dart';
import 'package:heyhip_amap/heyhip_marker_popup.dart';
import 'package:heyhip_amap/map_type.dart';
import 'package:heyhip_amap/marker_icon.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // HeyhipAmap.initKey(androidKey: "8669320b0376e085d9f6eacc409e14dc", iosKey: "793edbd4b3de840b61e4f1673e30b068");
  // 笔记本电脑
  // HeyhipAmap.initKey(androidKey: "d34d4dfce1761181098d1ae3bde58a33", iosKey: "793edbd4b3de840b61e4f1673e30b068");

  await HeyhipAmap.initKey(androidKey: "8669320b0376e085d9f6eacc409e14dc", iosKey: "793edbd4b3de840b61e4f1673e30b068");
  await HeyhipAmap.updatePrivacy(hasAgree: true, hasShow: true, hasContains: true);

  

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await HeyhipAmap.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }


  Future<void> testPermission() async {
    final has = await HeyhipAmap.hasLocationPermission();
    debugPrint('已有权限: $has');

    if (has != true){
            final granted = await HeyhipAmap.requestLocationPermission();
      debugPrint('申请结果: $granted');
    }

  }


  void testLocation() async {
    final location = await HeyhipAmap.getCurrentLocation();
    print('定位结果: $location');
    if (location != null) {
      final latitude = location['latitude'] as double;
      final longitude = location['longitude'] as double;

      // HeyhipAmap.moveCamera(
      //   latitude: latitude,
      //   longitude: longitude,
      //   zoom: 16,
      // );

      // mapController.moveCamera(latitude: latitude, longitude: longitude, zoom: 14);
      mapController.moveCamera(CameraPosition(target: LatLng(latitude, longitude)));

    }
  }

  void setZoom() async {
    mapController.setZoom(18);
  }

  void getPosition() async {
   final pos = await mapController.getCameraPosition();
    print(pos);
  }
  

  HeyhipAmapController mapController = HeyhipAmapController();

//   final markers = [
//   {
//     'id': 'marker_1',
//     'latitude': 30.482251,
//     'longitude': 104.080003,
//   },
//   {
//     'id': 'marker_2',
//     'latitude': 30.482351,
//     'longitude': 104.080103,
//   },
//   {
//     'id': 'marker_3',
//     'latitude': 30.482451,
//     'longitude': 104.080203,
//   },
//   {
//     'id': 'marker_4',
//     'latitude': 30.482551,
//     'longitude': 104.080303,
//   },
//   {
//     'id': 'marker_5',
//     'latitude': 30.482651,
//     'longitude': 104.080403,
//   },
//   {
//     'id': 'marker_6',
//     'latitude': 30.483200,
//     'longitude': 104.081000,
//   },
//   {
//     'id': 'marker_7',
//     'latitude': 30.483300,
//     'longitude': 104.081100,
//   },
//   {
//     'id': 'marker_8',
//     'latitude': 30.490000,
//     'longitude': 104.090000,
//   },
//   {
//     'id': 'marker_9',
//     'latitude': 30.490100,
//     'longitude': 104.090100,
//   },

 
// ];


final List<HeyhipMarker> markers = [
  HeyhipMarker(
    id: 'marker_1',
    latitude: 30.482251,
    longitude: 104.080003,
    icon: MarkerIcon.asset('assets/images/point.png'),
    popup: HeyhipMarkerPopup(title: "豆腐干恢复低功耗的法国", subtitle: "发生的固化速度发货速度发送给对方", avatar: "https://q6.itc.cn/q_70/images03/20250306/355fba6a5cb049f5b98c2ed9f03cc5e1.jpeg")
  ),
  HeyhipMarker(
    id: 'marker_2',
    latitude: 30.482351,
    longitude: 104.080103,
    icon: MarkerIcon.asset('assets/images/point.png')
  ),
  HeyhipMarker(
    id: 'marker_3',
    latitude: 30.482451,
    longitude: 104.080203,
    icon: MarkerIcon.asset('assets/images/point.png')
  ),
  HeyhipMarker(
    id: 'marker_4',
    latitude: 30.482551,
    longitude: 104.080303,
    icon: MarkerIcon.asset('assets/images/point.png')
  ),
  HeyhipMarker(
    id: 'marker_5',
    latitude: 30.482651,
    longitude: 104.080403,
    icon: MarkerIcon.asset('assets/images/point.png'),
    popup: HeyhipMarkerPopup(title: "孙大发噶啥都是打工的是法国士大夫")
  ),
  HeyhipMarker(
    id: 'marker_6',
    latitude: 30.4832,
    longitude: 104.081,
    icon: MarkerIcon.asset('assets/images/point.png')
  ),
  HeyhipMarker(
    id: 'marker_7',
    latitude: 30.4833,
    longitude: 104.0811,
    icon: MarkerIcon.asset('assets/images/point.png'),
    popup: HeyhipMarkerPopup(title: "房管局地方各级地方规划局法规和", subtitle: "但是发发啊手动阀手动阀山豆根士大夫嘎斯")
  ),
  HeyhipMarker(
    id: 'marker_8',
    latitude: 30.49,
    longitude: 104.09,
    icon: MarkerIcon.asset('assets/images/point.png'),
    popup: HeyhipMarkerPopup(title: "测试头像", subtitle: "这撒旦发射点", avatar: "https://q6.itc.cn/q_70/images03/20250306/355fba6a5cb049f5b98c2ed9f03cc5e1.jpeg")
  ),
  HeyhipMarker(
    id: 'marker_9',
    latitude: 30.4901,
    longitude: 104.0901,
    icon: MarkerIcon.asset('assets/images/point.png'),
    popup: HeyhipMarkerPopup(title: "测试")
  )
];

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
  children: [


    SizedBox(
      width: double.infinity,
      height: 500,
      child: HeyhipAmapView(
         latitude: 30.482251,
        longitude: 104.080003,
        zoom: 14,
        enableMarkerPopup: true,
        mapType: MapType.normal,
        // clusterEnabled: true,
        // clusterStyle: ClusterStyle(
        //   bgColor: Color(0xFFE91E63),
        //   textColor: Colors.blue,
        //   showStroke: true,
        //   strokeColor: Colors.black
        // ),
        controller: mapController,
        onMapCreated: () {
          mapController.onMapLoadFinish(() {
            print("地图完成");

           
          });

          mapController.onCameraMove((position) {


              // final LatLng target;
  // final double? zoom;
  // final double? tilt;
  // final double? bearing;
  var lat = position.target.latitude;
  var lng = position.target.longitude;
  var zoom = position.zoom;
  var tilt = position.tilt;
 debugPrint(
          '持续移动：LatLng=$lat latlng=$lng zoom=$zoom tilt=$tilt',
        );
          });

          mapController.onCameraIdle((position) {
  var lat = position.target.latitude;
  var lng = position.target.longitude;
  var zoom = position.zoom;
  var tilt = position.tilt;
 debugPrint(
          '移动结束：LatLng=$lat latlng=$lng zoom=$zoom tilt=$tilt',
        );
          });

          mapController.onCameraMoveStart((position) {
  var lat = position.target.latitude;
  var lng = position.target.longitude;
  var zoom = position.zoom;
  var tilt = position.tilt;
 debugPrint(
          '移动开始：LatLng=$lat latlng=$lng zoom=$zoom tilt=$tilt',
        );
          });

          mapController.onMapClick((latLng) {
              print('点击地图：${latLng.latitude}, ${latLng.longitude}');
              mapController.moveCamera(CameraPosition(target: latLng));
            });

            mapController.onMarkerPopupToggle(
      (markerId, isOpen, lat, lng) {
        debugPrint(
          'marker=$markerId popup=${isOpen ? "open" : "close"}',
        );
      },
    );

    mapController.onMarkerClick((id, laglng) {
debugPrint(
          'marker=${id}',
        );
    });

             mapController.setMarkers(markers);

        },
        
      ),
    ),

    Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text('Running on: $_platformVersion\n'),

            InkWell(
              onTap: testPermission,
              child: const Text('点击获取权限'),
            ),

            const SizedBox(height: 20),
            InkWell(
              onTap: testLocation,
              child: const Text('点击获取定位'),
            ),

            const SizedBox(height: 20),
            InkWell(
              onTap: setZoom,
              child: const Text('点击设置zoom'),
            ),

            const SizedBox(height: 20),
            InkWell(
              onTap: getPosition,
              child: const Text('获取Pos'),
            ),
          ],
        ),
      ),
    ),
  ],
),


        ),
    );
  }
}
