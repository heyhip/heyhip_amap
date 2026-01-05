import Flutter
import UIKit

public class HeyhipAmapPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "heyhip_amap", binaryMessenger: registrar.messenger())
    let instance = HeyhipAmapPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
  //   switch call.method {
  //   case "getPlatformVersion":
  //     result("iOS " + UIDevice.current.systemVersion)
  //   default:
  //     result(FlutterMethodNotImplemented)
  //   }
  // }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initAmap":
      handleInitAmap(call, result)
      break
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }


  private func handleInitAmap(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(
        FlutterError(
          code: "INVALID_ARGS",
          message: "Arguments are not a dictionary",
          details: nil
        )
      )
      return
    }

    let apiKey = args["apiKey"] as? String
    let agreePrivacy = args["agreePrivacy"] as? Bool

    if apiKey == nil || apiKey!.isEmpty {
      result(
        FlutterError(
          code: "INVALID_API_KEY",
          message: "apiKey is empty",
          details: nil
        )
      )
      return
    }

    if agreePrivacy != true {
      result(
        FlutterError(
          code: "PRIVACY_NOT_AGREED",
          message: "User has not agreed privacy policy",
          details: nil
        )
      )
      return
    }

    // AMapServices.shared().apiKey = apiKey!

    result(nil)
  }


}
