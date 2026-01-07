

import 'heyhip_amap_platform_interface.dart';
export 'amap_view.dart';


class HeyhipAmap {
  Future<String?> getPlatformVersion() {
    return HeyhipAmapPlatform.instance.getPlatformVersion();
  }

  // key + 隐私同意
  Future<void> init({required String apiKey, required bool agreePrivacy}) {
    return HeyhipAmapPlatform.instance.init(apiKey: apiKey, agreePrivacy: agreePrivacy);
  }


  // 获取当前定位
  Future<Map<String, dynamic>?> getCurrentLocation() {
    return HeyhipAmapPlatform.instance.getCurrentLocation();
  }

}
