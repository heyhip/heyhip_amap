import Flutter
import UIKit

class HeyhipAmapView: NSObject, FlutterPlatformView {

  private let containerView: UIView

  init(
    frame: CGRect,
    viewId: Int64,
    args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    // 创建一个普通 UIView
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .systemBlue
    super.init()
  }

  func view() -> UIView {
    return containerView
  }
}
