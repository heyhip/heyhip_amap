import Flutter
import UIKit
import MAMapKit

// class HeyhipAmapView: NSObject, FlutterPlatformView {

//   private let containerView: UIView

//   init(
//     frame: CGRect,
//     viewId: Int64,
//     args: Any?,
//     messenger: FlutterBinaryMessenger
//   ) {
//     // 创建一个普通 UIView
//     self.containerView = UIView(frame: frame)
//     self.containerView.backgroundColor = .systemBlue
//     self.containerView.backgroundColor = UIColor.red
//     super.init()
//   }

//   func view() -> UIView {
//     return containerView
//   }
// }


public class HeyhipAmapView: NSObject, FlutterPlatformView, MAMapViewDelegate {

    private let mapView: MAMapView
    
    private let channel: FlutterMethodChannel
    
    
    private var annotations: [String: MAPointAnnotation] = [:]
    
 
    // 是否开启持续移动
    private var enableCameraMoving: Bool = false

    
    // 用于持续移动
    private var isUserMoving = false
    private var displayLink: CADisplayLink?
    
    private var lastMoveCallbackTime: CFTimeInterval = 0
   
    private let moveCallbackInterval: CFTimeInterval = 0.2 // 300ms





  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
      
      self.channel = FlutterMethodChannel(
        name: "heyhip_amap_map_\(viewId)", binaryMessenger: messenger
      )


    // ⭐ 创建地图
    mapView = MAMapView(frame: frame)
//      mapView = MAMapView(frame: UIScreen.main.bounds)
      
      mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      
      
      super.init()
      mapView.delegate = self
      
      // 初始相机
      if let params = args as? [String: Any] {
        if
          let lat = params["latitude"] as? Double,
          let lng = params["longitude"] as? Double
        {
          let zoom = params["zoom"] as? Double ?? 14

          mapView.setCenter(
            CLLocationCoordinate2D(latitude: lat, longitude: lng),
            animated: false
          )
          mapView.zoomLevel = CGFloat(zoom)
        }
          
          if let enableMoving = params["enableCameraMoving"] as? Bool {
              enableCameraMoving = enableMoving
          }
          
      }
      
     
      
      

    // ⭐ 最基础配置（不开定位）
//      mapView.isScrollEnabled = true // 此属性用于地图滑动手势的开启和关闭
//      mapView.isZoomEnabled = true // 此属性用于地图缩放手势的开启和关闭
//      mapView.isRotateEnabled = true // 此属性用于地图旋转手势的开启和关闭
//      mapView.isRotateCameraEnabled = true // 此属性用于地图仰角手势的开启和关闭
////      mapView.isShowTraffic = true
      
      

//      mapView.isScrollEnabled = true   // 拖动
//      mapView.isZoomEnabled = true     // 缩放
//
//    mapView.isRotateEnabled = true
//    mapView.isRotateCameraEnabled = true
//    mapView.showsCompass = false
//    mapView.showsScale = false

    
      

      
      
      
      
      
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }

        switch call.method {
        case "moveCamera":
          self.handleMoveCamera(call: call, result: result)
        case "setMarkers":
            self.handleSetMarkers(call: call, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  public func view() -> UIView {
  // ⚠️ Flutter 布局完成后，这里才是正确大小
      print("🧭 mapView.delegate =", mapView.delegate as Any)
//      mapView.frame = UIScreen.main.bounds
    return mapView
  }
    
// 地图加载完成
    public func mapViewDidFinishLoadingMap(_ mapView: MAMapView) {
      print("✅ iOS AMap mapViewDidFinishLoadingMap")

      channel.invokeMethod("onMapLoaded", arguments: nil)
    }
    
    // 移动相机
    private func handleMoveCamera(
      call: FlutterMethodCall,
      result: @escaping FlutterResult
    ) {
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(
          code: "INVALID_ARGS",
          message: "arguments missing",
          details: nil
        ))
        return
      }

      guard
        let target = args["target"] as? [String: Any],
        let lat = target["latitude"] as? Double,
        let lng = target["longitude"] as? Double
      else {
        result(FlutterError(
          code: "INVALID_ARGS",
          message: "target missing",
          details: nil
        ))
        return
      }

      let zoom = args["zoom"] as? Double

      let coordinate = CLLocationCoordinate2D(
        latitude: lat,
        longitude: lng
      )

      // ⚠️ 高德 iOS：setCenter + zoomLevel
      mapView.setCenter(coordinate, animated: true)

      if let zoom = zoom {
        mapView.zoomLevel = CGFloat(zoom)
      }

      result(nil)
    }

    
    // 设置marker
    private func handleSetMarkers(
      call: FlutterMethodCall,
      result: @escaping FlutterResult
    ) {
      guard
        let args = call.arguments as? [String: Any],
        let markerList = args["markers"] as? [[String: Any]]
      else {
        result(FlutterError(
          code: "INVALID_ARGS",
          message: "markers missing",
          details: nil
        ))
        return
      }

      // ① 清空旧 marker
      if !annotations.isEmpty {
        mapView.removeAnnotations(Array(annotations.values))
        annotations.removeAll()
      }

      // ② 创建新 marker
      for item in markerList {

        guard
          let markerId = item["id"] as? String,
          let lat = item["latitude"] as? Double,
          let lng = item["longitude"] as? Double
        else {
          continue
        }

        let annotation = MAPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(
          latitude: lat,
          longitude: lng
        )

        // title 暂时不用（后面给 infoWindow 用）
        annotation.title = markerId

        annotations[markerId] = annotation
      }

      // ③ 加到地图
      mapView.addAnnotations(Array(annotations.values))

      result(nil)
    }

//    marker点击
    public func mapView(
      _ mapView: MAMapView,
      didSelect view: MAAnnotationView
    ) {
        // 立刻取消选中
          mapView.deselectAnnotation(view.annotation, animated: false)
        
      guard
        let annotation = view.annotation as? MAPointAnnotation,
        let markerId = annotation.title
      else {
        return
      }

      let args: [String: Any] = [
        "markerId": markerId,
        "latitude": annotation.coordinate.latitude,
        "longitude": annotation.coordinate.longitude
      ]

      channel.invokeMethod("onMarkerClick", arguments: args)
    }

    
    
    // 地图点击
    public func mapView(
      _ mapView: MAMapView,
      didSingleTappedAt coordinate: CLLocationCoordinate2D
    ) {
      let args: [String: Any] = [
        "latitude": coordinate.latitude,
        "longitude": coordinate.longitude
      ]

      channel.invokeMethod("onMapClick", arguments: args)
    }

    // 地图开始移动
    public func mapView(
      _ mapView: MAMapView,
      mapWillMoveByUser wasUserAction: Bool
    ) {
      guard wasUserAction else { return }
        
        if enableCameraMoving {
            isUserMoving = true
              startDisplayLink()
        }
       
        
        let center = mapView.centerCoordinate

      channel.invokeMethod("onCameraMoveStart", arguments: [
        "latitude": center.latitude,
        "longitude": center.longitude,
        "zoom": mapView.zoomLevel,
        "tilt": 0,
        "bearing": mapView.rotationDegree,
      ])
    }

    // 地图移动结束
    public func mapView(
      _ mapView: MAMapView,
      mapDidMoveByUser wasUserAction: Bool
    ) {
      guard wasUserAction else { return }

      
        
        if enableCameraMoving {
            isUserMoving = false
              stopDisplayLink()
        }
        
      let center = mapView.centerCoordinate

      channel.invokeMethod("onCameraIdle", arguments: [
        "latitude": center.latitude,
        "longitude": center.longitude,
        "zoom": mapView.zoomLevel,
        "tilt": 0,
        "bearing": mapView.rotationDegree,
      ])
    }

    
    private func startDisplayLink() {
      stopDisplayLink()

      displayLink = CADisplayLink(
        target: self,
        selector: #selector(onDisplayLinkTick)
      )
      displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
      displayLink?.invalidate()
      displayLink = nil
    }

    @objc private func onDisplayLinkTick() {
      guard isUserMoving else { return }
        
        let now = CACurrentMediaTime()
          guard now - lastMoveCallbackTime >= moveCallbackInterval else {
            return
          }
          lastMoveCallbackTime = now

      let center = mapView.centerCoordinate

      channel.invokeMethod("onCameraMove", arguments: [
        "latitude": center.latitude,
        "longitude": center.longitude,
        "zoom": mapView.zoomLevel,
        "tilt": 0,
        "bearing": mapView.rotationDegree,
      ])
    }

    
    
}
