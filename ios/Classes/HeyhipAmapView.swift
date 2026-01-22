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


    // ======================
    // 聚合开关 & 样式
    // ======================
    private var clusterEnabled: Bool = false
    private var clusterStyle: [String: Any]?

    // ======================
    // marker 缓存
    // ======================
    private var itemAnnotations: [String: MAPointAnnotation] = [:]
    private var clusterAnnotations: [String: MAPointAnnotation] = [:]

    // 最近一轮
    private var lastMarkers: [[String: Any]]?
    private var lastZoomLevel: Int = -1
    private var lastGridSize: Int = -1
    private var lastVisibleRect: MAMapRect?




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



  public func view() -> UIView {
  // ⚠️ Flutter 布局完成后，这里才是正确大小
//      print("🧭 mapView.delegate =", mapView.delegate as Any)
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
    // 设置 marker（支持聚合 / 非聚合）
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

        // =========================
        // ① 清空地图上【所有】旧标注
        // （⚠️ 非常关键，避免 annotationView 复用导致聚合“看不见”）
        // =========================
        if !mapView.annotations.isEmpty {
            mapView.removeAnnotations(mapView.annotations)
        }

        // =========================
        // ② 清空所有缓存
        // =========================
        annotations.removeAll()
        itemAnnotations.removeAll()
        clusterAnnotations.removeAll()

        lastZoomLevel = -1
        lastGridSize = -1
        lastVisibleRect = nil

        // 记录最新 markers
        lastMarkers = markerList

        // =========================
        // ③ 根据是否开启聚合，走不同逻辑
        // =========================
        if clusterEnabled {

            // 👉 聚合模式：只走聚合渲染
            refreshClusters(markerList)

        } else {

            // 👉 非聚合模式：直接加普通 marker
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
                annotation.title = markerId

                annotations[markerId] = annotation
            }

            if !annotations.isEmpty {
                mapView.addAnnotations(Array(annotations.values))
            }
        }

        result(nil)
    }

    
    
    private func colorFromHex(_ value: UInt32) -> UIColor {
        let a = CGFloat((value >> 24) & 0xFF) / 255.0
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    
    public func mapView(
        _ mapView: MAMapView,
        viewFor annotation: MAAnnotation
    ) -> MAAnnotationView? {

        guard let point = annotation as? MAPointAnnotation else {
            return nil
        }

        let isCluster =
            point.subtitle != nil &&
            (Int(point.subtitle ?? "") ?? 0) > 1

        let reuseId = isCluster
            ? "cluster_annotation"
            : "single_annotation"

        let reuseView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            ?? MAAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

        guard let view = reuseView else {
            return nil
        }

        view.annotation = annotation
        view.canShowCallout = false


        // ✅ 复用安全：先清
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        view.image = nil

        if isCluster {

            let count = Int(point.subtitle!)!

            let bgColor = colorFromHex(
                clusterStyle?["bgColor"] as? UInt32 ?? 0xFF3F51B5
            )
            let textColor = colorFromHex(
                clusterStyle?["textColor"] as? UInt32 ?? 0xFFFFFFFF
            )
            let showStroke = clusterStyle?["showStroke"] as? Bool ?? true
            let strokeColor = colorFromHex(
                clusterStyle?["strokeColor"] as? UInt32 ?? 0xFFFFFFFF
            )

            let size: CGFloat = 40
            view.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view.centerOffset = CGPoint(x: 0, y: -size / 2)

            let circle = CAShapeLayer()
            circle.path = UIBezierPath(
                ovalIn: CGRect(x: 0, y: 0, width: size, height: size)
            ).cgPath
            circle.fillColor = bgColor.cgColor

            if showStroke {
                circle.strokeColor = strokeColor.cgColor
                circle.lineWidth = 2
            }

            view.layer.addSublayer(circle)

            let text = CATextLayer()
            text.string = "\(count)"
            text.alignmentMode = .center
            text.foregroundColor = textColor.cgColor
            text.fontSize = 14
            text.contentsScale = UIScreen.main.scale
            text.frame = CGRect(x: 0, y: 9, width: size, height: 22)

            view.layer.addSublayer(text)

        } else {
            // 单点
            view.image = UIImage(named: "amap_marker")
            view.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
            view.centerOffset = CGPoint(x: 0, y: -12)
        }

        return view
    }


    
    
    
    public func mapView(
        _ mapView: MAMapView,
        regionDidChangeAnimated animated: Bool
    ) {
        if let markers = lastMarkers {
            refreshClusters(markers)
        }
    }


    
    private func refreshClusters(_ markers: [[String: Any]]) {

        let zoom = mapView.zoomLevel
        let zoomLevel = Int(floor(zoom))
        let gridSize = clusterEnabled ? getClusterGridSize(zoom) : 0

        let visibleRect = getVisibleMapRect()

        if zoomLevel == lastZoomLevel,
           gridSize == lastGridSize,
           let lastRect = lastVisibleRect,
           MAMapRectEqualToRect(lastRect, visibleRect) {
            return
        }


        // 可视区域 items
        var items: [ClusterItem] = []

        for m in markers {
            guard
                let id = m["id"] as? String,
                let lat = m["latitude"] as? Double,
                let lng = m["longitude"] as? Double
            else { continue }

            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            if !isInVisibleRect(coord) { continue }

            items.append(ClusterItem(id: id, coordinate: coord))
        }

        let clusters = buildClusters(
            items: items,
            gridSize: gridSize,
            zoomLevel: zoomLevel
        )

        var newKeys = Set<String>()

        for cluster in clusters {

            if cluster.items.count == 1 {
                let item = cluster.items[0]
                newKeys.insert(item.id)

                let ann = itemAnnotations[item.id] ?? {
                    let a = MAPointAnnotation()
                    a.coordinate = item.coordinate
                    mapView.addAnnotation(a)
                    itemAnnotations[item.id] = a
                    return a
                }()

                ann.coordinate = item.coordinate

            } else {

                let p = latLngToWorldPoint(
                    latitude: cluster.center.latitude,
                    longitude: cluster.center.longitude,
                    zoomLevel: zoomLevel
                )

                let key = buildClusterId(
                    point: p,
                    gridSize: gridSize,
                    zoomLevel: zoomLevel
                )

                newKeys.insert(key)

                let ann = clusterAnnotations[key] ?? {
                    let a = MAPointAnnotation()
                    a.coordinate = cluster.center
                    a.subtitle = "\(cluster.items.count)"
                    mapView.addAnnotation(a)
                    clusterAnnotations[key] = a
                    return a
                }()

                ann.coordinate = cluster.center
            }
        }

        // diff 删除
        itemAnnotations.keys
            .filter { !newKeys.contains($0) }
            .forEach {
                if let a = itemAnnotations.removeValue(forKey: $0) {
                    mapView.removeAnnotation(a)
                }
            }

        clusterAnnotations.keys
            .filter { !newKeys.contains($0) }
            .forEach {
                if let a = clusterAnnotations.removeValue(forKey: $0) {
                    mapView.removeAnnotation(a)
                }
            }

        lastZoomLevel = zoomLevel
        lastGridSize = gridSize
        lastVisibleRect = visibleRect
        lastMarkers = markers
    }

    
    private func buildClusters(
        items: [ClusterItem],
        gridSize: Int,
        zoomLevel: Int
    ) -> [Cluster] {

        // 不聚合
        if gridSize <= 0 {
            return items.map {
                let c = Cluster()
                c.items = [$0]
                c.center = $0.coordinate
                return c
            }
        }

        var gridMap: [String: Cluster] = [:]
        var clusters: [Cluster] = []

        for item in items {

            let p = latLngToWorldPoint(
                latitude: item.coordinate.latitude,
                longitude: item.coordinate.longitude,
                zoomLevel: zoomLevel
            )

            let gx = Int(p.x) / gridSize
            let gy = Int(p.y) / gridSize
            let key = "\(gx)_\(gy)"

            let cluster: Cluster
            if let c = gridMap[key] {
                cluster = c
            } else {
                cluster = Cluster()
                gridMap[key] = cluster
                clusters.append(cluster)
            }

            cluster.items.append(item)
        }

        // 计算中心点
        for cluster in clusters {
            var lat = 0.0
            var lng = 0.0

            for item in cluster.items {
                lat += item.coordinate.latitude
                lng += item.coordinate.longitude
            }

            let count = Double(cluster.items.count)
            cluster.center = CLLocationCoordinate2D(
                latitude: lat / count,
                longitude: lng / count
            )
        }

        return clusters
    }

    private func buildClusterId(
        point: CGPoint,
        gridSize: Int,
        zoomLevel: Int
    ) -> String {

        if gridSize <= 0 {
            return "single_\(zoomLevel)_\(Int(point.x))_\(Int(point.y))"
        }

        let gx = Int(point.x) / gridSize
        let gy = Int(point.y) / gridSize

        return "cluster_\(zoomLevel)_\(gx)_\(gy)"
    }

    
    private class ClusterItem {
        let id: String
        let coordinate: CLLocationCoordinate2D

        init(id: String, coordinate: CLLocationCoordinate2D) {
            self.id = id
            self.coordinate = coordinate
        }
    }

    private class Cluster {
        var items: [ClusterItem] = []
        var center: CLLocationCoordinate2D!
    }

    
    private func getVisibleMapRect() -> MAMapRect {
        return mapView.visibleMapRect
    }

    private func isInVisibleRect(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let point = MAMapPointForCoordinate(coordinate)
        let rect = mapView.visibleMapRect
        return MAMapRectContainsPoint(rect, point)
    }


    
    private func getClusterGridSize(_ zoom: Double) -> Int {
        if zoom < 5 { return 200 }
        if zoom < 8 { return 120 }
        if zoom < 11 { return 80 }
        if zoom < 14 { return 60 }
        if zoom < 17 { return 40 }
        return 0
    }

    
    
    private func latLngToWorldPoint(
        latitude: Double,
        longitude: Double,
        zoomLevel: Int
    ) -> CGPoint {

        let siny = min(
            max(sin(latitude * .pi / 180), -0.9999),
            0.9999
        )

        let x = 256.0 * (0.5 + longitude / 360.0)
        let y = 256.0 * (
            0.5 - log((1 + siny) / (1 - siny)) / (4 * .pi)
        )

        let scale = pow(2.0, Double(zoomLevel))

        return CGPoint(
            x: x * scale,
            y: y * scale
        )
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
