import Flutter
import UIKit
import MAMapKit
import CoreLocation



public class HeyhipAmapPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {

  private let locationManager = CLLocationManager()
    

      private var locationResult: FlutterResult?

      private var locationTimeoutWorkItem: DispatchWorkItem?
      private let locationTimeout: TimeInterval = 10.0


  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "heyhip_amap", binaryMessenger: registrar.messenger())
    let instance = HeyhipAmapPlugin()

    instance.locationManager.delegate = instance

    registrar.addMethodCallDelegate(instance, channel: channel)

    

    // ⭐ 先注册一个“占位用”的 PlatformView
    registrar.register(
      // HeyhipAmapViewFactory(),
        HeyhipAmapViewFactory(messenger: registrar.messenger(), registrar: registrar),
      
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
//        AMapServices.shared().enableHTTPS = true

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

      case "getCurrentLocation":
        // 1️⃣ 检查权限
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
          status = self.locationManager.authorizationStatus
        } else {
          status = CLLocationManager.authorizationStatus()
        }

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
          result(
            FlutterError(
              code: "NO_PERMISSION",
              message: "Location permission not granted",
              details: nil
            )
          )
          return
        }

        // 2️⃣ 防止并发调用
        if self.locationResult != nil {
          result(
            FlutterError(
              code: "LOCATION_IN_PROGRESS",
              message: "Location request already in progress",
              details: nil
            )
          )
          return
        }

        self.locationResult = result

        // 3️⃣ 启动定位
        DispatchQueue.main.async {
          self.locationManager.startUpdatingLocation()
        }

        // 4️⃣ 超时兜底
        let workItem = DispatchWorkItem { [weak self] in
          guard let self = self, let result = self.locationResult else { return }

          self.locationManager.stopUpdatingLocation()
          self.locationResult = nil

          result(
            FlutterError(
              code: "LOCATION_TIMEOUT",
              message: "Location request timeout",
              details: nil
            )
          )
        }

        self.locationTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(
          deadline: .now() + self.locationTimeout,
          execute: workItem
        )


    case "hasLocationPermission":
      let status: CLAuthorizationStatus
      if #available(iOS 14.0, *) {
        status = self.locationManager.authorizationStatus
      } else {
        status = CLLocationManager.authorizationStatus()
      }

      let granted = (
        status == .authorizedWhenInUse ||
        status == .authorizedAlways
      )
      result(granted)

    case "requestLocationPermission":
      DispatchQueue.main.async {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
          status = self.locationManager.authorizationStatus
        } else {
          status = CLLocationManager.authorizationStatus()
        }

        if status == .notDetermined {
          self.locationManager.requestWhenInUseAuthorization()
        }
      }
      result(nil)

    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }



  public func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    guard
      let location = locations.last,
      let result = self.locationResult
    else {
      return
    }

    // 停止定位
    manager.stopUpdatingLocation()

    // 取消超时
    self.locationTimeoutWorkItem?.cancel()
    self.locationTimeoutWorkItem = nil
    self.locationResult = nil

    let data: [String: Any] = [
      "latitude": location.coordinate.latitude,
      "longitude": location.coordinate.longitude,
      "accuracy": location.horizontalAccuracy,
      "speed": location.speed,
      "bearing": location.course,
      "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000)
    ]

    result(data)
  }




}
