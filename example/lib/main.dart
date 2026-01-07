import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:heyhip_amap/heyhip_amap.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _heyhipAmapPlugin = HeyhipAmap();

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
          await _heyhipAmapPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

static const _channel = MethodChannel('heyhip_amap');

  Future<void> testPermission() async {
    final has =
        await _channel.invokeMethod<bool>('hasLocationPermission');
    debugPrint('已有权限: $has');

    if (has != true) {
      final granted = await _channel
          .invokeMethod<bool>('requestLocationPermission');
      debugPrint('申请结果: $granted');
    }
  }


  void testLocation() async {
    final location = await _heyhipAmapPlugin.getCurrentLocation();
    print('定位结果: $location');
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(children: [
            Container(
              height: 500,
              child: AMapView(),
            ),

              Text('Running on: $_platformVersion\n'),

              InkWell(
                onTap: () {
                  _heyhipAmapPlugin.init(apiKey: "1f92f4cb144f3dc30c27e1dd49543a6b", agreePrivacy: true);
                },
                child: Text('点击初始化地图'),
              ),

              InkWell(
                onTap: () {
                  testPermission();
                },
                child: Text('点击获取权限'),
              ),

              InkWell(
                onTap: () {
                  testLocation();
                },
                child: Text('点击获取定位'),
              ),


          ],)
        ),
      ),
    );
  }
}
