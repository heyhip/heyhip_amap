import Flutter
import UIKit

class HeyhipAmapViewFactory: NSObject, FlutterPlatformViewFactory {

  private let messenger: FlutterBinaryMessenger
  private let registrar: FlutterPluginRegistrar

  init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
    self.messenger = messenger
    self.registrar = registrar
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

    return HeyhipAmapView(
      frame: frame,
      viewId: viewId,
      args: args,
      messenger: messenger,
      registrar: registrar
    )
  }
}
