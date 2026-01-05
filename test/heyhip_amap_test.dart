import 'package:flutter_test/flutter_test.dart';
import 'package:heyhip_amap/heyhip_amap.dart';
import 'package:heyhip_amap/heyhip_amap_platform_interface.dart';
import 'package:heyhip_amap/heyhip_amap_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHeyhipAmapPlatform
    with MockPlatformInterfaceMixin
    implements HeyhipAmapPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final HeyhipAmapPlatform initialPlatform = HeyhipAmapPlatform.instance;

  test('$MethodChannelHeyhipAmap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHeyhipAmap>());
  });

  test('getPlatformVersion', () async {
    HeyhipAmap heyhipAmapPlugin = HeyhipAmap();
    MockHeyhipAmapPlatform fakePlatform = MockHeyhipAmapPlatform();
    HeyhipAmapPlatform.instance = fakePlatform;

    expect(await heyhipAmapPlugin.getPlatformVersion(), '42');
  });
}
