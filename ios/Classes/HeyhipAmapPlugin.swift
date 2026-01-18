import Flutter
import UIKit

public class HeyhipAmapPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "heyhip_amap", binaryMessenger: registrar.messenger())
    let instance = HeyhipAmapPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)


    // ⭐ 先注册一个“占位用”的 PlatformView
    registrar.register(
      HeyhipAmapViewFactory(),
      withId: "heyhip_amap_map"
    )

  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }







}
