import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'heyhip_amap_method_channel.dart';

abstract class HeyhipAmapPlatform extends PlatformInterface {
  /// Constructs a HeyhipAmapPlatform.
  HeyhipAmapPlatform() : super(token: _token);

  static final Object _token = Object();

  static HeyhipAmapPlatform _instance = MethodChannelHeyhipAmap();

  /// The default instance of [HeyhipAmapPlatform] to use.
  ///
  /// Defaults to [MethodChannelHeyhipAmap].
  static HeyhipAmapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HeyhipAmapPlatform] when
  /// they register themselves.
  static set instance(HeyhipAmapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  // 初始化
  Future<void> initKey({required String apiKey});

  /// 隐私合规
  Future<void> updatePrivacy({
    required bool hasContains,
    required bool hasShow,
    required bool hasAgree,
  }) {
    throw UnimplementedError('updatePrivacy() has not been implemented.');
  }

  // 是否有权限
  Future<bool> hasLocationPermission();

  // 请求权限
  Future<bool> requestLocationPermission();

  // 获取当前定位
  Future<Map<String, dynamic>?> getCurrentLocation();

}
