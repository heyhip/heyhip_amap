class HeyhipMarkerPopup {
  final String? title;
  final String? subtitle;
  final String? avatar;

  const HeyhipMarkerPopup({
    required this.title,
    this.subtitle,
    this.avatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'avatar': avatar,
    };
  }
}
