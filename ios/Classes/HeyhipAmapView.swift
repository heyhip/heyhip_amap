import Flutter
import UIKit
import MAMapKit


class HeyhipPointAnnotation: MAPointAnnotation {
  var iconInfo: [String: Any]?
    var popup: [String: Any]?
}

class HeyhipInfoWindowView: UIView {

  init(popup: [String: Any]) {
    super.init(frame: CGRect(x: 0, y: 0, width: 220, height: 80))

    backgroundColor = .white
    layer.cornerRadius = 8
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.15
    layer.shadowRadius = 6
    layer.shadowOffset = CGSize(width: 0, height: 2)

    let titleLabel = UILabel()
    titleLabel.font = .boldSystemFont(ofSize: 14)
    titleLabel.text = popup["title"] as? String
    titleLabel.frame = CGRect(x: 12, y: 10, width: 196, height: 18)
    addSubview(titleLabel)

    if let subtitle = popup["subtitle"] as? String {
      let subLabel = UILabel()
      subLabel.font = .systemFont(ofSize: 12)
      subLabel.textColor = .darkGray
      subLabel.text = subtitle
      subLabel.frame = CGRect(x: 12, y: 32, width: 196, height: 16)
      addSubview(subLabel)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}



public class HeyhipAmapView: NSObject, FlutterPlatformView, MAMapViewDelegate {

    
    private let mapView: MAMapView
    
    private let channel: FlutterMethodChannel
    
    private let registrar: FlutterPluginRegistrar

    // 当前正在显示 InfoWindow 的 annotation
    private weak var showingAnnotation: HeyhipPointAnnotation?

    // 当前显示的 InfoWindow view
    private weak var showingInfoWindow: UIView?

    
    
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


  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
      
      self.registrar = registrar
      
      self.channel = FlutterMethodChannel(
        name: "heyhip_amap_map_\(viewId)", binaryMessenger: messenger
      )

      // ⭐ 创建地图
      self.mapView = MAMapView(frame: frame)
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
      return mapView
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

//            let ann = MAPointAnnotation()
            let ann = HeyhipPointAnnotation()
            ann.coordinate = CLLocationCoordinate2D(
                latitude: lat,
                longitude: lng
            )
            ann.title = id

            if let icon = item["icon"] as? [String: Any] {
              ann.iconInfo = icon
            }
            
            if let popup = item["popup"] as? [String: Any] {
              ann.popup = popup
            }
            
            annotations[id] = ann
        }

        // ③ 一次性加到地图
        if !annotations.isEmpty {
            mapView.addAnnotations(Array(annotations.values))
        }

        result(nil)
    }
    
    
    
    public func mapView(
      _ mapView: MAMapView,
      viewFor annotation: MAAnnotation
    ) -> MAAnnotationView? {

      guard let ann = annotation as? HeyhipPointAnnotation else {
        return nil
      }

      let reuseId = "heyhip_marker"
      var view = mapView.dequeueReusableAnnotationView(
        withIdentifier: reuseId
      )

      if view == nil {
        view = MAAnnotationView(
          annotation: ann,
          reuseIdentifier: reuseId
        )
      }

      view?.annotation = ann
      view?.canShowCallout = false
    view?.image = nil
        
        
        
        // ===== InfoWindow =====
        view?.subviews
          .filter { $0 is HeyhipInfoWindowView }
          .forEach { $0.removeFromSuperview() }

//        if let popup = ann.popup {
//          let infoView = HeyhipInfoWindowView(popup: popup)
//
//          infoView.center = CGPoint(
//            x: view!.bounds.width / 2,
//            y: -infoView.bounds.height / 2 - 8
//          )
//
//          view?.addSubview(infoView)
//        }
        
        view?.canShowCallout = false
        view?.subviews.forEach { sub in
          if sub is HeyhipInfoWindowView {
            sub.removeFromSuperview()
          }
        }



      // ⭐ 处理 icon
      if let iconInfo = ann.iconInfo,
         let type = iconInfo["type"] as? String {

        switch type {

        case "asset":
//          if let path = iconInfo["value"] as? String {
//            view?.image = UIImage(named: path)
//          }
            
            if let path = iconInfo["value"] as? String {
//                let key = registrar.lookupKey(forAsset: path)
//                view?.image = UIImage(contentsOfFile: key)
                
                let assetKey = registrar.lookupKey(forAsset: path)
                let assetPath = Bundle.main.path(forResource: assetKey, ofType: nil)
                view?.image = assetPath.flatMap { UIImage(contentsOfFile: $0) }

              }

        case "network":
          if let urlStr = iconInfo["value"] as? String,
             let url = URL(string: urlStr) {
            // ⚠️ 建议后面用 SDWebImage
            DispatchQueue.global().async {
              if let data = try? Data(contentsOf: url),
                 let image = UIImage(data: data) {
                DispatchQueue.main.async {
                  view?.image = image
                }
              }
            }
          }

        case "base64":
          if let base64 = iconInfo["value"] as? String,
             let data = Data(base64Encoded: base64),
             let image = UIImage(data: data) {
            view?.image = image
          }

        default:
          break
        }
      }
        
        // ===== 强烈推荐：尺寸 + 锚点 =====
        let width = (ann.iconInfo?["iconWidth"] as? Double) ?? 40
        let height = (ann.iconInfo?["iconHeight"] as? Double) ?? 40

        view?.bounds = CGRect(
          x: 0,
          y: 0,
          width: width,
          height: height
        )

        // 让 marker 底部对准经纬度点（和 Android / 高德一致）
        view?.centerOffset = CGPoint(
          x: 0,
          y: -height / 2
        )

      return view
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
//          mapView.deselectAnnotation(view.annotation, animated: false)
        
      guard
        let annotation = view.annotation as? HeyhipPointAnnotation,
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
        
        
        // ===== 情况 1：再次点击同一个 marker → 关闭 =====
          if showingAnnotation === annotation {
            showingInfoWindow?.removeFromSuperview()
            showingInfoWindow = nil
            showingAnnotation = nil

            mapView.deselectAnnotation(annotation, animated: false)
            return
          }
        
        // ===== 情况 2：点击了其他 marker → 先关旧的 =====
          showingInfoWindow?.removeFromSuperview()
          showingInfoWindow = nil
          showingAnnotation = nil

          // ===== 没有 popup 不显示 =====
          guard let popup = annotation.popup else {
            mapView.deselectAnnotation(annotation, animated: false)
            return
          }

          // ===== 创建 InfoWindow =====
          let infoView = HeyhipInfoWindowView(popup: popup)

          infoView.center = CGPoint(
            x: view.bounds.width / 2,
            y: -infoView.bounds.height / 2 - 8
          )

          view.addSubview(infoView)

          // ===== 记录当前状态 =====
          showingInfoWindow = infoView
          showingAnnotation = annotation

          // 立刻取消系统选中态（否则会影响再次点击）
          mapView.deselectAnnotation(annotation, animated: false)
        
        
    }

    
    
    // 地图点击
    public func mapView(
      _ mapView: MAMapView,
      didSingleTappedAt coordinate: CLLocationCoordinate2D
    ) {
        
        showingInfoWindow?.removeFromSuperview()
          showingInfoWindow = nil
          showingAnnotation = nil
        
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
        guard mapView.window != nil else { return }
        
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
        channel.setMethodCallHandler(nil)
        mapView.delegate = nil
    }

    
}
