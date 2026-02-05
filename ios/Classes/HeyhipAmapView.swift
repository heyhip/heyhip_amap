 import Flutter
import UIKit
import MAMapKit
import SDWebImage
import AMapSearchKit


struct HeyhipMarkerIcon {

    enum IconType: String {
        case asset
        case network
        case base64
    }

    let type: IconType
    let value: String
    let width: CGFloat
    let height: CGFloat


    init?(map: [String: Any]) {
        guard
            let typeStr = map["type"] as? String,
            let type = IconType(rawValue: typeStr),
            let value = map["value"] as? String
        else {
            return nil
        }

        self.type = type
        self.value = value
        self.width = CGFloat(map["width"] as? Double ?? 48)
        self.height = CGFloat(map["height"] as? Double ?? 48)
    }
}





struct HeyhipMarkerPopup {
    let title: String?
    let subtitle: String?
    let avatar: String?

    init(map: [String: Any]) {
        self.title = map["title"] as? String
        self.subtitle = map["subtitle"] as? String
        self.avatar = map["avatar"] as? String
    }
}


class HeyhipPointAnnotation: MAPointAnnotation {
  var icon: HeyhipMarkerIcon?
    
    var popup: HeyhipMarkerPopup?
}

final class TriangleView: UIView {

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.close()

        UIColor.white.setFill()
        path.fill()
    }
}



final class HeyhipInfoWindowView: UIView {

    init(popup: HeyhipMarkerPopup) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI(popup: popup)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(popup: HeyhipMarkerPopup) {

        // =========================
        // 容器（竖向）
        // =========================
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .center
        container.spacing = 0
        addSubview(container)

        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // =========================
        // 气泡主体
        // =========================
        let bubble = UIView()
        bubble.backgroundColor = .white
        bubble.layer.cornerRadius = 10
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false
        
        // 阴影
        bubble.layer.shadowColor = UIColor.black.cgColor
        bubble.layer.shadowOpacity = 0.15
        bubble.layer.shadowRadius = 4
        bubble.layer.shadowOffset = CGSize(width: 0, height: 2)
        bubble.layer.masksToBounds = false


        container.addArrangedSubview(bubble)

        // =========================
        // 横向内容
        // =========================
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        bubble.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 6),
            contentStack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -6),
            contentStack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 8),
            contentStack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -8),
        ])

        // =========================
        // avatar
        // =========================
        if let avatar = popup.avatar, !avatar.isEmpty {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layer.cornerRadius = 18
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 1
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.backgroundColor = .lightGray

            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 36),
                imageView.heightAnchor.constraint(equalToConstant: 36)
            ])

            contentStack.addArrangedSubview(imageView)
            
            
            if let url = URL(string: avatar) {
                    imageView.sd_setImage(
                        with: url,
                        placeholderImage: nil,
                        options: [.retryFailed, .continueInBackground]
                    )
                }
        }

        // =========================
        // 文本区域
        // =========================
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading

        if let title = popup.title {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textColor = UIColor(white: 0.2, alpha: 1)
            textStack.addArrangedSubview(label)
        }

        if let subtitle = popup.subtitle {
            let label = UILabel()
            label.text = subtitle
            label.font = .systemFont(ofSize: 12)
            label.textColor = UIColor(white: 0.4, alpha: 1)
            textStack.addArrangedSubview(label)
        }

        contentStack.addArrangedSubview(textStack)

        // =========================
        // 箭头
        // =========================
        let arrow = TriangleView()
        arrow.backgroundColor = .clear
        arrow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            arrow.widthAnchor.constraint(equalToConstant: 12),
            arrow.heightAnchor.constraint(equalToConstant: 6)
        ])

        container.addArrangedSubview(arrow)
    }
}




// 聚合
final class ClusterItem {
    let id: String
    let coordinate: CLLocationCoordinate2D

    init(id: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}


final class Cluster {
    var items: [ClusterItem] = []
    var center: CLLocationCoordinate2D = .init(latitude: 0, longitude: 0)
}

private func latLngToWorldPoint(
    _ coord: CLLocationCoordinate2D,
    zoomLevel: Int
) -> CGPoint {

    let siny = min(max(sin(coord.latitude * .pi / 180), -0.9999), 0.9999)

    let x = 256 * (0.5 + coord.longitude / 360)
    let y = 256 * (0.5 - log((1 + siny) / (1 - siny)) / (4 * .pi))

    let scale = pow(2.0, Double(zoomLevel))

    return CGPoint(
        x: x * scale,
        y: y * scale
    )
}


func clusterGridSize(for zoom: CGFloat) -> Int {
    if zoom > 13 {
        return 0   // 🔥 13 级以上，不聚合
    } else if zoom > 11 {
        return 60
    } else if zoom > 9 {
        return 80
    } else {
        return 120
    }
}





private var kAssociatedImageURLKey: UInt8 = 0

extension MAAnnotationView {
    var heyhipImageURL: URL? {
        get {
            objc_getAssociatedObject(self, &kAssociatedImageURLKey) as? URL
        }
        set {
            objc_setAssociatedObject(
                self,
                &kAssociatedImageURLKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

extension UIImage {
    func heyhip_resized(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}







public class HeyhipAmapView: NSObject, FlutterPlatformView, MAMapViewDelegate, AMapSearchDelegate {

    private let searchAPI: AMapSearchAPI
    // 保存 FlutterResult（异步回调用）
    private var pendingPoiResult: FlutterResult?

    
    private let mapView: MAMapView
    
    private let channel: FlutterMethodChannel
    
    private let registrar: FlutterPluginRegistrar

    // 当前正在显示 InfoWindow 的 annotation
    private weak var showingAnnotation: HeyhipPointAnnotation?

    // 当前显示的 InfoWindow view
    private weak var showingInfoWindow: UIView?
    private var enableMarkerPopup: Bool = false
    
    
    
    private var annotations: [String: MAPointAnnotation] = [:]
    private var clusterAnnotations: [MAPointAnnotation] = []
    
    private var didNotifyMapLoaded = false
    private var isDetached = false
        
 
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
    
    
    /// 上一次用于聚合的 zoom（向下取整）
    private var lastClusterZoom: Int?



  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
      
      self.registrar = registrar
      
      self.channel = FlutterMethodChannel(
        name: "heyhip_amap_map_\(viewId)", binaryMessenger: messenger
      )

      // ⭐ 创建地图
      self.mapView = MAMapView(frame: frame)
      mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      

      self.searchAPI = AMapSearchAPI()
      super.init()
      self.searchAPI.delegate = self

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
          
          if let popup = params["enableMarkerPopup"] as? Bool {
              enableMarkerPopup = popup
          }

          
      }
      
      
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }

        switch call.method {
        case "detach":
           self.handleDetach(result: result)
            break;
        case "moveCamera":
         self.handleMoveCamera(call: call, result: result)
            break;
        case "setMarkers":
           self.handleSetMarkers(call: call, result: result)
            break;
        case "setZoom":
           self.handleSetZoom(call: call, result: result)
            break;
        case "getCameraPosition":
           self.handleGetCameraPosition(result: result)
            break;
        case "searchPoisByLatLng":
           self.handleSearchPoisByLatLng(call: call, result: result)
            break;
        case "searchPoisByText":
           self.handleSearchPoisByText(call: call, result: result)
            break;
        case "setMapType":
            if let type = call.arguments as? Int {
                self.applyMapType(type)
            }
            
            break;
        default:
            break;
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

        case 2:
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
        guard !self.isDetached else { return }
        guard !didNotifyMapLoaded else { return }
        
        didNotifyMapLoaded = true
        
        safeInvoke("onMapLoaded", arguments: nil)

    }

    
    // 移动相机
    private func handleMoveCamera(
      call: FlutterMethodCall,
      result: @escaping FlutterResult
    ) {
        
        guard !self.isDetached else { return }
        
      guard let args = call.arguments as? [String: Any] else {
        return
      }

      guard
        let target = args["target"] as? [String: Any],
        let lat = target["latitude"] as? Double,
        let lng = target["longitude"] as? Double
      else {
          
          DispatchQueue.main.async {
              result(FlutterError(code: "INVALID_ARGUMENT", message: nil, details: call.arguments))
          }

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
    }

    
    // 设置marker
    private func handleSetMarkers(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard !self.isDetached else { return }

        guard
            let args = call.arguments as? [String: Any],
            let markers = args["markers"] as? [[String: Any]]
        else {
            DispatchQueue.main.async {
                result(FlutterError(code: "INVALID_ARGUMENT", message: nil, details: call.arguments))
            }
            return
        }
        
        
        DispatchQueue.main.async {
        // ① 清空旧点
            if !self.annotations.isEmpty {
                self.mapView.removeAnnotations(Array(self.annotations.values))
                self.annotations.removeAll()
        }

        // ② 创建新点
        for item in markers {
            guard
                let id = item["id"] as? String,
                let lat = item["latitude"] as? Double,
                let lng = item["longitude"] as? Double
            else { continue }

            let ann = HeyhipPointAnnotation()
            ann.coordinate = CLLocationCoordinate2D(
                latitude: lat,
                longitude: lng
            )
            ann.title = id

            if let icon = item["icon"] as? [String: Any] {
              ann.icon = HeyhipMarkerIcon(map: icon)
            }
            
            if let popupMap = item["popup"] as? [String: Any] {
                ann.popup = HeyhipMarkerPopup(map: popupMap)
            }
            
            self.annotations[id] = ann
        }


        
            self.refreshClusters()
        }

    }
    
    
    
    public func mapView(
      _ mapView: MAMapView,
      viewFor annotation: MAAnnotation
    ) -> MAAnnotationView? {
        
        guard !self.isDetached else { return nil }
        
        // ===== 聚合点 =====
        if annotation.title == "__cluster__" {

            let reuseId = "clusterView"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)

            if view == nil {
                view = MAAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                view?.canShowCallout = false
            }

            let count = Int(annotation.subtitle ?? "0") ?? 0

            let size: CGFloat
            switch count {
            case 0..<10:  size = 36
            case 10..<50: size = 42
            case 50..<100: size = 48
            default: size = 54
            }

            view?.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view?.centerOffset = CGPoint(x: 0, y: -size / 2)

            // 清掉旧内容（⚠️ 非常重要）
            view?.subviews.forEach { $0.removeFromSuperview() }

            // 背景圆
            let bg = UIView(frame: view!.bounds)
            bg.backgroundColor = UIColor.systemBlue
            bg.layer.cornerRadius = size / 2
            bg.layer.masksToBounds = true

            // 数字
            let label = UILabel(frame: bg.bounds)
            label.text = "\(count)"
            label.textAlignment = .center
            label.textColor = .white
            label.font = UIFont.boldSystemFont(ofSize: 14)

            bg.addSubview(label)
            view?.addSubview(bg)

            return view
        }



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
//        view?.transform = .identity
        view?.canShowCallout = false

        // ================================
        // ⭐ 1️⃣ 彻底清理复用状态
        // ================================
        view?.image = nil
        view?.heyhipImageURL = nil
//        view?.subviews.forEach { $0.removeFromSuperview() }
        
        let width = ann.icon?.width ?? 48
        let height = ann.icon?.height ?? 48

        // ================================
        // ⭐ 3️⃣ 设置 AnnotationView 尺寸
        // ================================
        view?.frame = CGRect(x: 0, y: 0, width: width, height: height)
        view?.bounds = view?.frame ?? .zero

        // marker 底部对齐经纬度
        view?.centerOffset = CGPoint(x: 0, y: -height / 2)
        
        // ================================
        // ⭐ 5️⃣ 加载 icon
        // ================================
        if let icon = ann.icon {

            switch icon.type {

                case .asset:
                    // 本地资源
                    let assetKey = registrar.lookupKey(forAsset: icon.value)
                    if let path = Bundle.main.path(forResource: assetKey, ofType: nil),
                       let image = UIImage(contentsOfFile: path) {
                        view?.image = image.heyhip_resized(
                            to: CGSize(width: icon.width, height: icon.height)
                        )
                    }
                

                    case .network:
                        if let url = URL(string: icon.value) {
                            view?.heyhipImageURL = url

                            SDWebImageManager.shared.loadImage(
                                with: url,
                                options: [.retryFailed],
                                progress: nil
                            ) { [weak view] image, _, _, _, _, _ in
                                DispatchQueue.main.async {
                                    // ✅ 防止复用错位
                                    guard view?.heyhipImageURL == url else { return }

                                    // ✅ 用下载回来的 image，而不是 UIImage(named:)
                                    if let image = image {
                                        view?.image = image.heyhip_resized(
                                            to: CGSize(width: icon.width, height: icon.height)
                                        )
                                    }
                                }
                            }
                        }


                case .base64:
                    if let data = Data(base64Encoded: icon.value),
                    let image = UIImage(data: data) {
                        view?.image = image.heyhip_resized(
                            to: CGSize(width: icon.width, height: icon.height)
                        )
                    }

                }
            
            
                

            }
        
        
      return view
    }

    
    // 聚合
    private func buildClusters(
        items: [ClusterItem],
        gridSize: Int,
        zoomLevel: Int
    ) -> [Cluster] {
        
        guard !self.isDetached else { return [] }

        guard gridSize > 0 else {
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
            let p = latLngToWorldPoint(item.coordinate, zoomLevel: zoomLevel)

            let gx = Int(p.x) / gridSize
            let gy = Int(p.y) / gridSize
            let key = "\(gx)_\(gy)"

            let cluster = gridMap[key] ?? {
                let c = Cluster()
                gridMap[key] = c
                clusters.append(c)
                return c
            }()

            cluster.items.append(item)
        }

        // 计算中心点
        for cluster in clusters {
            let count = Double(cluster.items.count)
            let lat = cluster.items.reduce(0) { $0 + $1.coordinate.latitude }
            let lng = cluster.items.reduce(0) { $0 + $1.coordinate.longitude }

            cluster.center = CLLocationCoordinate2D(
                latitude: lat / count,
                longitude: lng / count
            )
        }

        return clusters
    }

    
    
    
    
    // ======================
    // 刷新聚合（核心）
    // ======================
    private func refreshClusters() {
        guard !self.isDetached else { return }

        // 1️⃣ 如果没开聚合，直接显示原始 marker
        guard clusterEnabled else {
//            mapView.removeAnnotations(mapView.annotations)
            mapView.removeAnnotations(Array(annotations.values))
            mapView.removeAnnotations(clusterAnnotations)
            clusterAnnotations.removeAll()
            mapView.addAnnotations(Array(annotations.values))
            return
        }

        // 只在 zoom 变化时才刷新
        let zoomLevel = Int(mapView.zoomLevel)
        if lastClusterZoom == zoomLevel {
            return
        }
        lastClusterZoom = zoomLevel
        
        let gridSize = clusterGridSize(for: mapView.zoomLevel)
        

        // 2️⃣ 原始 marker → ClusterItem
        let items: [ClusterItem] = annotations.values.compactMap {
            guard let id = $0.title else { return nil }
            return ClusterItem(id: id, coordinate: $0.coordinate)
        }

        // 3️⃣ 算聚合
        let clusters = buildClusters(
            items: items,
            gridSize: gridSize,
            zoomLevel: zoomLevel
        )

        // 4️⃣ 清空地图上所有 annotation
//        mapView.removeAnnotations(mapView.annotations)
        mapView.removeAnnotations(Array(annotations.values))
        mapView.removeAnnotations(clusterAnnotations)
        clusterAnnotations.removeAll()
        

        // 5️⃣ 重新生成 annotation
        var newAnnotations: [MAPointAnnotation] = []

        for cluster in clusters {
            if cluster.items.count == 1 {
                // ===== 单点：原来的 HeyhipPointAnnotation =====
                let item = cluster.items[0]
                if let ann = annotations[item.id] {
                    newAnnotations.append(ann)
                }
            } else {
                // ===== 聚合点 =====
                let ann = MAPointAnnotation()
                ann.coordinate = cluster.center
//                ann.title = "cluster_\(cluster.items.count)"
                ann.title = "__cluster__"
                ann.subtitle = "\(cluster.items.count)"
                newAnnotations.append(ann)
                
                clusterAnnotations.append(ann)
            }
        }

        // 6️⃣ 加回地图
        mapView.addAnnotations(newAnnotations)
    }

    
    
    
    
    public func mapView(
      _ mapView: MAMapView,
      mapDidZoomByUser wasUserAction: Bool
    ) {
        guard !self.isDetached else { return }
        
        guard wasUserAction else { return }

        refreshClusters()
    }
    

    
    public func mapView(
        _ mapView: MAMapView,
        regionDidChangeAnimated animated: Bool
    ) {
        guard !self.isDetached else { return }
        
        let currentZoom = Int(mapView.zoomLevel)

        // ⭐ 只在 zoom 真正变化时才刷新聚合
        if lastClusterZoom != currentZoom {
            refreshClusters()
        }
    }


    
    // 设置zoom
    private func handleSetZoom(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        guard !self.isDetached else { return }
        
        guard
            let args = call.arguments as? [String: Any],
            let zoom = args["zoom"] as? Double
        else {
            DispatchQueue.main.async {
                self.failResult(result, "INVALID_HEYHIP")
            }
            return
        }

        // ⚠️ iOS 高德 zoomLevel 是 CGFloat
        mapView.zoomLevel = CGFloat(zoom)
    }

    // 获取相机定位
    private func handleGetCameraPosition(
        result: @escaping FlutterResult
    ) {
        guard !self.isDetached else { return }
        
        let center = mapView.centerCoordinate

        
        DispatchQueue.main.async {
            result([
                "latitude": center.latitude,
                "longitude": center.longitude,
                "zoom": self.mapView.zoomLevel,
                "tilt": 0,
                "bearing": self.mapView.rotationDegree
            ])
        }
    }

    
    
    private func handleSearchPoisByLatLng(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        
        // ⭐ 新增：防止并发覆盖
        guard pendingPoiResult == nil else {
            DispatchQueue.main.async {
                self.failResult(result, "INVALID_HEYHIP")
            }
            return
        }

        
        guard let args = call.arguments as? [String: Any],
              let lat = args["latitude"] as? Double,
              let lng = args["longitude"] as? Double
        else {
            DispatchQueue.main.async {
                self.failResult(result, "INVALID_HEYHIP")
            }
            return
        }

        let radius = args["radius"] as? Int ?? 1000
        let keyword = args["keyword"] as? String
        let page = args["page"] as? Int ?? 1
        let pageSize = args["pageSize"] as? Int ?? 20

        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(
            withLatitude: CGFloat(lat),
            longitude: CGFloat(lng)
        )
        request.radius = radius
        request.sortrule = 0      // 距离优先
        request.page = page
        request.offset = pageSize

        if let keyword = keyword, !keyword.isEmpty {
            request.keywords = keyword
        }
        
        pendingPoiResult = result
        searchAPI.aMapPOIAroundSearch(request)
    }
    
    
    
    private func handleSearchPoisByText(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        // ⭐ 新增：防止并发覆盖
        guard pendingPoiResult == nil else {
            DispatchQueue.main.async {
                self.failResult(result, "INVALID_HEYHIP")
            }
            return
        }

        
        guard
            let args = call.arguments as? [String: Any],
            let keyword = args["keyword"] as? String
        else {
            DispatchQueue.main.async {
                self.failResult(result, "INVALID_HEYHIP")
            }
            return
        }

        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = keyword

        // 可选：城市
        if let city = args["city"] as? String, !city.isEmpty {
            request.city = city
        }

        // 可选：是否限制在城市内
        request.cityLimit = args["cityLimit"] as? Bool ?? false

        // 分页
        request.page = args["page"] as? Int ?? 1
        request.offset = args["pageSize"] as? Int ?? 20

        // 👇 可选：中心点（只影响排序，不是周边搜索）
        if
            let lat = args["latitude"] as? Double,
            let lng = args["longitude"] as? Double
        {
            request.location = AMapGeoPoint.location(
                withLatitude: CGFloat(lat),
                longitude: CGFloat(lng)
            )
        }

        self.pendingPoiResult = result
        self.searchAPI.aMapPOIKeywordsSearch(request)
    }

    


    public func onPOISearchDone(
        _ request: AMapPOISearchBaseRequest!,
        response: AMapPOISearchResponse!
    ) {
        
        guard let result = pendingPoiResult else { return }
        pendingPoiResult = nil

        guard let pois = response.pois else {
            DispatchQueue.main.async {
                result([])
            }
            return
        }

        // 3️⃣ POI → Map
        let list: [[String: Any]] = pois.map { poi in
            
            // ⭐ 关键：distance 用 Optional
            let distance: Double? = poi.distance > 0
                ? Double(poi.distance)
                : nil
            
            return [
                "id": poi.uid ?? "",
                "name": poi.name ?? "",
                "latitude": poi.location.latitude,
                "longitude": poi.location.longitude,
                "address": poi.address ?? "",
                "type": poi.type ?? "",
                "distance": distance as Any,
                "pcode": poi.pcode ?? "",
                "adcode": poi.adcode ?? ""
            ]
        }

        // 4️⃣ 回传 Flutter
        DispatchQueue.main.async {
            result(list)
        }
    }
    

//    marker点击
    public func mapView(
      _ mapView: MAMapView,
      didSelect view: MAAnnotationView
    ) {
        // ===== 0️⃣ 聚合点：什么都不做（交给 view 点击）=====
        if view.annotation?.title == "__cluster__" {
            return
        }

        guard let annotation = view.annotation as? HeyhipPointAnnotation,
              let markerId = annotation.title
        else {
            return
        }
        
        
        // =========================
        // 1️⃣ enableMarkerPopup = true → 只做 popup toggle
        // =========================
        if enableMarkerPopup {

            // 再次点击同一个 → 关闭
            if showingAnnotation === annotation {
                showingInfoWindow?.removeFromSuperview()
                showingInfoWindow = nil
                showingAnnotation = nil

                mapView.deselectAnnotation(annotation, animated: false)
                return
            }

            // 点击其他 marker → 关旧的，开新的
            DispatchQueue.main.async {
                self.showInfoWindow(for: annotation, from: view)
            }

            mapView.deselectAnnotation(annotation, animated: false)
            return
        }
        
        
        // =========================
        // 2️⃣ enableMarkerPopup = false → 回调 onMarkerClick
        // =========================
        let args: [String: Any] = [
            "markerId": markerId,
            "latitude": annotation.coordinate.latitude,
            "longitude": annotation.coordinate.longitude
        ]

        safeInvoke("onMarkerClick", arguments: args)

        mapView.deselectAnnotation(annotation, animated: false)
        
    }
    
    
    private func showInfoWindow(
      for annotation: HeyhipPointAnnotation,
      from markerView: MAAnnotationView
    ) {
        
        // 关闭旧的
        showingInfoWindow?.removeFromSuperview()
        showingInfoWindow = nil
        showingAnnotation = nil

        guard let popup = annotation.popup else { return }

        let infoView = HeyhipInfoWindowView(popup: popup)

        // ⚠️ 不要用 AutoLayout
        infoView.translatesAutoresizingMaskIntoConstraints = true

        // ① 先算 size（关键）
        let size = infoView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize
        )

        // ② 设置 frame
        infoView.frame = CGRect(
            x: (markerView.bounds.width - size.width) / 2,
            y: -size.height - 6, // 只往上，不减 marker 高度
            width: size.width,
            height: size.height
        )

        // ③ 加到 markerView
        markerView.addSubview(infoView)

        showingInfoWindow = infoView
        showingAnnotation = annotation
    }


    // 地图点击
    public func mapView(
      _ mapView: MAMapView,
      didSingleTappedAt coordinate: CLLocationCoordinate2D
    ) {
        
        guard !self.isDetached else { return }
        
        showingInfoWindow?.removeFromSuperview()
          showingInfoWindow = nil
          showingAnnotation = nil
        
      let args: [String: Any] = [
        "latitude": coordinate.latitude,
        "longitude": coordinate.longitude
      ]

        safeInvoke("onMapClick", arguments: args)

    }

    // 地图开始移动
    public func mapView(
      _ mapView: MAMapView,
      mapWillMoveByUser wasUserAction: Bool
    ) {
        
        guard !self.isDetached else { return }
        
      guard wasUserAction else { return }
        
        if enableCameraMoving {
            isUserMoving = true
              startDisplayLink()
        }
       
        
        let center = mapView.centerCoordinate

        
        safeInvoke("onCameraMoveStart", arguments: [
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
        
        refreshClusters()
        
      let center = mapView.centerCoordinate

        
        safeInvoke("onCameraIdle", arguments: [
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
        // guard !self.isDetached else { return }
      displayLink?.invalidate()
      displayLink = nil
    }

    @objc private func onDisplayLinkTick() {
        guard !self.isDetached else { return }
        guard displayLink != nil else { return }
        guard isUserMoving else { return }

        
        let now = CACurrentMediaTime()
          guard now - lastMoveCallbackTime >= moveCallbackInterval else {
            return
          }
          lastMoveCallbackTime = now

      let center = mapView.centerCoordinate
        
        
        safeInvoke("onCameraMove", arguments: [
            "latitude": center.latitude,
            "longitude": center.longitude,
            "zoom": self.mapView.zoomLevel,
            "tilt": 0,
            "bearing": self.mapView.rotationDegree,
          ])
        
        
    }
    
    private func safeInvoke(
        _ method: String,
        arguments: Any? = nil
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.isDetached else { return }
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }
    
    private func failResult(
      _ result: FlutterResult,
      _ code: String,
      _ message: String? = nil,
      _ details: Any? = nil
    ) {
      result(FlutterError(code: code, message: message, details: details))
    }



    private func handleDetach(result: @escaping FlutterResult) {
        
        stopDisplayLink()
        pendingPoiResult = nil
        
        searchAPI.cancelAllRequests()
        mapView.removeFromSuperview()
        
        // 2️⃣ 解绑 delegate（防止后续回调）
        mapView.delegate = nil
        searchAPI.delegate = nil

        channel.setMethodCallHandler(nil)
        annotations.removeAll()
        clusterAnnotations.removeAll()
    }

    
    deinit {
        
        stopDisplayLink()
        pendingPoiResult = nil
        
        searchAPI.cancelAllRequests()
        mapView.removeFromSuperview()
        
        // 2️⃣ 解绑 delegate（防止后续回调）
        mapView.delegate = nil
        searchAPI.delegate = nil

        channel.setMethodCallHandler(nil)
        annotations.removeAll()
        clusterAnnotations.removeAll()

    }

    
}
