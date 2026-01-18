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
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "arguments missing",
            details: nil
          )
        )
        return
      }

      guard
        let hasContains = args["hasContains"] as? Bool,
        let hasShow = args["hasShow"] as? Bool,
        let hasAgree = args["hasAgree"] as? Bool
      else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "privacy args missing",
            details: nil
          )
        )
        return
      }
 
        // ⚠️ 顺序非常重要（官方要求）
//         AMapServices.shared().setPrivacyHasShown(hasShow ? .didShow : .notShow)
//         AMapServices.shared().setPrivacyHasContained(hasContains ? .didContain : .notContain)
//         AMapServices.shared().setPrivacyHasAgreed(hasAgree ? .didAgree : .notAgree)
//        
//        let services = AMapServices.shared()
//        services.setshow
//
//        services.setPrivacyHasContained(
//            hasContains
//              ? AMapPrivacyInfoStatus.didContain
//              : AMapPrivacyInfoStatus.notContain
//          )
//
//          services.setPrivacyHasShown(
//            hasShow
//              ? AMapPrivacyShowStatus.didShow
//              : AMapPrivacyShowStatus.notShow
//          )
//
//          services.setPrivacyHasAgreed(
//            hasAgree
//              ? AMapPrivacyAgreeStatus.didAgree
//              : AMapPrivacyAgreeStatus.notAgree
//          )

      result(nil)


    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }







}
