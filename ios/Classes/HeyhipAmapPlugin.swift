import Flutter
import UIKit
import MAMapKit



public class HeyhipAmapPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "heyhip_amap", binaryMessenger: registrar.messenger())
    let instance = HeyhipAmapPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)


    // ⭐ 先注册一个“占位用”的 PlatformView
    registrar.register(
      // HeyhipAmapViewFactory(),
      HeyhipAmapViewFactory(messenger: registrar.messenger()),
      withId: "heyhip_amap_map"
    )

  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

      case "initKey":
     
        guard let args = call.arguments as? [String: Any] else {
            result(
              FlutterError(
                code: "INVALID_ARGS",
                message: "arguments missing",
                details: nil
              )
            )
            return
          }
        
        guard let key = args["apiKey"] as? String, !key.isEmpty else {
            result(
              FlutterError(
                code: "INVALID_ARGS",
                message: "apiKey missing",
                details: nil
              )
            )
            return
          }
    
        AMapServices.shared().apiKey = key

      result(nil)

    case "updatePrivacy":
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "arguments missing", details: nil))
            return
        }

        let hasContains = args["hasContains"] as? Bool ?? false
        let hasShow = args["hasShow"] as? Bool ?? false
        let hasAgree = args["hasAgree"] as? Bool ?? false

        if (!hasShow || !hasContains || !hasAgree) {
            result(FlutterError(code: "INVALID_ARGS", message: "Agree to the Privacy Policy", details: nil))
            return
        }
        
        MAMapView.updatePrivacyShow(AMapPrivacyShowStatus.didShow, privacyInfo: AMapPrivacyInfoStatus.didContain)
        MAMapView.updatePrivacyAgree(AMapPrivacyAgreeStatus.didAgree)

      result(nil)


    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }







}
