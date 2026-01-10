class AMapUiSettings {
  final bool zoomControlsEnabled;      // 加减号
  final bool compassEnabled;           // 指南针
  final bool scaleControlsEnabled;     // 比例尺
  final bool myLocationButtonEnabled;  // 定位按钮

  final bool rotateGesturesEnabled;    // 旋转手势
  final bool tiltGesturesEnabled;      // 倾斜手势
  final bool zoomGesturesEnabled;      // 缩放手势

  const AMapUiSettings({
    this.zoomControlsEnabled = false, // ⭐ 默认关闭加减号
    this.compassEnabled = false,
    this.scaleControlsEnabled = false,
    this.myLocationButtonEnabled = false,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomGesturesEnabled = true,
  });

  Map<String, Object> toMap() {
    return {
      'zoomControlsEnabled': zoomControlsEnabled,
      'compassEnabled': compassEnabled,
      'scaleControlsEnabled': scaleControlsEnabled,
      'myLocationButtonEnabled': myLocationButtonEnabled,
      'rotateGesturesEnabled': rotateGesturesEnabled,
      'tiltGesturesEnabled': tiltGesturesEnabled,
      'zoomGesturesEnabled': zoomGesturesEnabled,
    };
  }
}
