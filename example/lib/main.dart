import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:heyhip_amap/heyhip_amap.dart';
import 'package:heyhip_amap/heyhip_amap_controller.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  HeyhipAmap.initKey(androidKey: "8669320b0376e085d9f6eacc409e14dc", iosKey: "");
  HeyhipAmap.updatePrivacy(hasAgree: true, hasShow: true, hasContains: true);

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

      mapController.moveCamera(latitude: latitude, longitude: longitude, zoom: 14);

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
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Center(
          child: Column(children: [
            Container(
              height: 500,
              child: HeyhipAmapView(
                // latitude: 30.477718,
                // longitude: 104.085527,
                // zoom: 14,
                controller: mapController,
                onMapCreated: () {
                  mapController.onMapLoadFinish(() {
                    print("地图完成");
                  });
                },
              ),
            ),

              Text('Running on: $_platformVersion\n'),


              InkWell(
                onTap: () {
                  testPermission();
                },
                child: Text('点击获取权限'),
              ),

              SizedBox(height: 20,),
              InkWell(
                onTap: () {
                  testLocation();
                },
                child: Text('点击获取定位'),
              ),

              SizedBox(height: 20,),
              InkWell(
                onTap: () {
                  setZoom();
                },
                child: Text('点击设置zoom'),
              ),

              SizedBox(height: 20,),
              InkWell(
                onTap: () {
                  getPosition();
                },
                child: Text('获取Pos'),
              ),



          ],)
        ),
        )
      ),
    );
  }
}
