import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'heyhip_amap_platform_interface.dart';

/// An implementation of [HeyhipAmapPlatform] that uses method channels.
class MethodChannelHeyhipAmap extends HeyhipAmapPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('heyhip_amap');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> initKey({required String apiKey}) async {
    try {
      await methodChannel.invokeMethod('initKey', {'apiKey': apiKey});
    } on PlatformException catch (e) {
      print(e.code);
      print(e.message);
    }
  }

  @override
  Future<void> updatePrivacy({
    required bool hasContains,
    required bool hasShow,
    required bool hasAgree,
  }) async {
    try {
      await methodChannel.invokeMethod('updatePrivacy', {
        'hasContains': hasContains,
        'hasShow': hasShow,
        'hasAgree': hasAgree,
      });
    } on PlatformException catch (e) {
      print(e.code);
      print(e.message);
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    return await methodChannel.invokeMethod('hasLocationPermission');
  }

  @override
  Future<bool> requestLocationPermission() async {
    return await methodChannel.invokeMethod('requestLocationPermission');
  }

  @override
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    final result = await methodChannel.invokeMethod('getCurrentLocation');
    return Map<String, dynamic>.from(result);
  }
}
