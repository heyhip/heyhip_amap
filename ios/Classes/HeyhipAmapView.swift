import Flutter
import UIKit
import MAMapKit

class HeyhipAmapContainerView: UIView {

    let mapView: MAMapView

    init(frame: CGRect, mapView: MAMapView) {
        self.mapView = mapView
        super.init(frame: frame)
        addSubview(mapView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mapView.frame = bounds
        NSLog("[HeyhipAmap] layoutSubviews bounds = %@", NSCoder.string(for: bounds))
    }
}


public class HeyhipAmapView: NSObject, FlutterPlatformView, MAMapViewDelegate {

    private let containerView: HeyhipAmapContainerView
    
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


    // ======================
    // 聚合开关 & 样式
    // ======================
    private var clusterEnabled: Bool = false
    private var clusterStyle: [String: Any]?


  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
      
      self.channel = FlutterMethodChannel(
        name: "heyhip_amap_map_\(viewId)", binaryMessenger: messenger
      )

      // ⭐ 创建地图
      self.mapView = MAMapView(frame: frame)
      
      
      self.containerView = HeyhipAmapContainerView(
                  frame: frame,
                  mapView: mapView
              )

      super.init()
      
    
      mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

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
          
          if let mapTypeValue = params["mapType"] as? Int {
                  applyMapType(mapTypeValue)
              }
          
          if let ui = params["uiSettings"] as? [String: Any] {
              // ===== 指南针 =====
                if let compass = ui["compassEnabled"] as? Bool {
                  mapView.showsCompass = compass
                }

                // ===== 比例尺 =====
                if let scale = ui["scaleControlsEnabled"] as? Bool {
                  mapView.showsScale = scale
                }

                // ===== 旋转手势 =====
                if let rotate = ui["rotateGesturesEnabled"] as? Bool {
                  mapView.isRotateEnabled = rotate
                }

                // ===== 倾斜（仰角）手势 =====
                if let tilt = ui["tiltGesturesEnabled"] as? Bool {
                  mapView.isRotateCameraEnabled = tilt
                }

                // ===== 缩放手势 =====
                if let zoomGesture = ui["zoomGesturesEnabled"] as? Bool {
                  mapView.isZoomEnabled = zoomGesture
                }
          }
          
          if let enabled = params["clusterEnabled"] as? Bool {
              clusterEnabled = enabled
          }

          if let style = params["clusterStyle"] as? [String: Any] {
              clusterStyle = style
          }

          
      }
      
      
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }

        switch call.method {
        case "moveCamera":
          self.handleMoveCamera(call: call, result: result)
        case "setMarkers":
            self.handleSetMarkers(call: call, result: result)
        case "setZoom":
            self.handleSetZoom(call: call, result: result)
        case "getCameraPosition":
            self.handleGetCameraPosition(result: result);
            break;
        case "setMapType":
            if let type = call.arguments as? Int {
                self.applyMapType(type)
            }
            result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }
    
    public func view() -> UIView {
    // ⚠️ Flutter 布局完成后，这里才是正确大小
  //      print("🧭 mapView.delegate =", mapView.delegate as Any)
  //      mapView.frame = UIScreen.main.bounds
        
        print("mapView.frame =", mapView.frame)

        
//      return mapView
        return self.containerView
    }
    
    // 地图类型
    private func applyMapType(_ type: Int) {
        switch type {
        case 1: // satellite
            mapView.mapType = .satellite

        case 2: // night（Android night → iOS naviNight）
            mapView.mapType = .naviNight

        case 3: // navi
            mapView.mapType = .navi

        case 4: // bus
            mapView.mapType = .bus

        default: // normal
            mapView.mapType = .standard
        }
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
        
        NSLog("🔥 HeyhipAmapView init")

        guard
            let args = call.arguments as? [String: Any],
            let markers = args["markers"] as? [[String: Any]]
        else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "markers missing",
                details: nil
            ))
            return
        }

        // ① 清空旧点
        if !annotations.isEmpty {
            mapView.removeAnnotations(Array(annotations.values))
            annotations.removeAll()
        }

        // ② 创建新点
        for item in markers {
            guard
                let id = item["id"] as? String,
                let lat = item["latitude"] as? Double,
                let lng = item["longitude"] as? Double
            else { continue }

            let ann = MAPointAnnotation()
            ann.coordinate = CLLocationCoordinate2D(
                latitude: lat,
                longitude: lng
            )
            ann.title = id

            annotations[id] = ann
        }

        // ③ 一次性加到地图
        if !annotations.isEmpty {
            mapView.addAnnotations(Array(annotations.values))
        }

        result(nil)
    }

    
    // 设置zoom
    private func handleSetZoom(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard
            let args = call.arguments as? [String: Any],
            let zoom = args["zoom"] as? Double
        else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "zoom missing",
                details: nil
            ))
            return
        }

        // ⚠️ iOS 高德 zoomLevel 是 CGFloat
        mapView.zoomLevel = CGFloat(zoom)

        result(nil)
    }

    // 获取相机定位
    private func handleGetCameraPosition(
        result: @escaping FlutterResult
    ) {
        let center = mapView.centerCoordinate

        result([
            "latitude": center.latitude,
            "longitude": center.longitude,
            "zoom": mapView.zoomLevel,
            "tilt": 0,
            "bearing": mapView.rotationDegree
        ])
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

    
    deinit {
        stopDisplayLink()
        mapView.delegate = nil
    }

    
}
