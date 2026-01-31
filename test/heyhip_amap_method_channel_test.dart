import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heyhip_amap/heyhip_amap_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelHeyhipAmap platform = MethodChannelHeyhipAmap();
  const MethodChannel channel = MethodChannel('heyhip_amap');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
