import Flutter
import UIKit

class HeyhipAmapViewFactory: NSObject, FlutterPlatformViewFactory {

  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  // ⭐⭐⭐ 必须实现（iOS 17+）
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {

    print("✅ HeyhipAmapViewFactory create called, frame = \(frame)")

    return HeyhipAmapView(
      frame: frame,
      viewId: viewId,
      args: args,
      messenger: messenger
    )
  }
}
