import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:heyhip_amap/heyhip_location.dart';

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
    } on PlatformException catch (_) {
      // print(e.code);
      // print(e.message);
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
    } on PlatformException catch (_) {
      // print(e.code);
      // print(e.message);
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    return await methodChannel.invokeMethod('hasLocationPermission');
  }

  @override
  Future<void> requestLocationPermission() async {
    await methodChannel.invokeMethod('requestLocationPermission');
  }

  @override
  Future<HeyhipLocation?> getCurrentLocation() async {
      final result = await methodChannel.invokeMethod<Map>('getCurrentLocation');

      if (result == null) return null;

      return HeyhipLocation.fromMap(
        Map<String, dynamic>.from(result),
      );
  }
}
