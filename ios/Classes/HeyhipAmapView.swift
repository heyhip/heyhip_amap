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


public class HeyhipAmapView: NSObject, FlutterPlatformView {

    private let containerView: UIView
  private let mapView: MAMapView

  init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {

      

       self.containerView = UIView(frame: frame)
       self.containerView.backgroundColor = .systemBlue
       self.containerView.backgroundColor = UIColor.red
      
    // ⭐ 创建地图
    mapView = MAMapView(frame: frame)

    // ⭐ 最基础配置（不开定位）
    mapView.isRotateEnabled = true
    mapView.isRotateCameraEnabled = true
    mapView.showsCompass = false
    mapView.showsScale = false

    // ⭐ 解析 creationParams（先只用经纬度和 zoom）
    if let params = args as? [String: Any] {
      if
        let lat = params["latitude"] as? Double,
        let lng = params["longitude"] as? Double
      {
        let zoom = params["zoom"] as? Double ?? 14

        mapView.setCenter(
          CLLocationCoordinate2D(latitude: lat, longitude: lng),
          // zoomLevel: CGFloat(zoom),
          animated: false
        )
        mapView.zoomLevel = CGFloat(zoom)
          mapView.backgroundColor = UIColor.red

      }
    }
      
      self.containerView.addSubview(mapView)

    super.init()
  }

  public func view() -> UIView {
//    return mapView
      return containerView
  }
}
