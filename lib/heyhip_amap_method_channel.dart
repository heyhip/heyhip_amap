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
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> init({required String apiKey, required bool agreePrivacy}) async {
    final Map<String, dynamic> params = {
      'apiKey': apiKey,
      'agreePrivacy': agreePrivacy,
    };

    try {
      await methodChannel.invokeMethod('init', params);
    } on PlatformException catch (e) {
      print(e.code);
      print(e.message);
    }

  }



}
