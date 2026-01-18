import Flutter
import UIKit

class DummyAmapViewFactory: NSObject, FlutterPlatformViewFactory {

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return DummyAmapView(frame: frame)
  }
}
