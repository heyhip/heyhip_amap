import 'dart:ui';

class ClusterStyle {
  final Color bgColor;
  final Color textColor;
  final bool showStroke;
  final Color strokeColor;

  const ClusterStyle({
    this.bgColor = const Color(0xFF3F51B5),
    this.textColor = const Color(0xFFFFFFFF),
    this.showStroke = true,
    this.strokeColor = const Color(0xFFFFFFFF),
  });

  Map<String, dynamic> toMap() {
    return {
      'bgColor': bgColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'showStroke': showStroke,
      'strokeColor': strokeColor.toARGB32(),
    };
  }
}
