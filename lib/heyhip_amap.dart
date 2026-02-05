import 'dart:io';

import 'package:heyhip_amap/heyhip_location.dart';

import 'heyhip_amap_platform_interface.dart';
export 'heyhip_amap_view.dart';

class HeyhipAmap {
  HeyhipAmap._(); // 🔒 禁止实例化

  static bool _inited = false;

  /// 初始化 Key（只调用一次）
  static Future<void> initKey({
    required String androidKey,
    required String iosKey,
  }) async {
    if (_inited) return;

    final apiKey = Platform.isAndroid ? androidKey : iosKey;

    await HeyhipAmapPlatform.instance.initKey(apiKey: apiKey);

    _inited = true;
  }

  /// 隐私合规（可多次调用）
  static Future<void> updatePrivacy({
    required bool hasContains,
    required bool hasShow,
    required bool hasAgree,
  }) {
    return HeyhipAmapPlatform.instance.updatePrivacy(
      hasContains: hasContains,
      hasShow: hasShow,
      hasAgree: hasAgree,
    );
  }

  static Future<String?> getPlatformVersion() {
    return HeyhipAmapPlatform.instance.getPlatformVersion();
  }

  // 是否有权限
  static Future<bool> hasLocationPermission() {
    return HeyhipAmapPlatform.instance.hasLocationPermission();
  }

  // 请求权限
  static Future<void> requestLocationPermission() {
    return HeyhipAmapPlatform.instance.requestLocationPermission();
  }

  // 获取当前定位
  static Future<HeyhipLocation?> getCurrentLocation() {
    return HeyhipAmapPlatform.instance.getCurrentLocation();
  }
}
