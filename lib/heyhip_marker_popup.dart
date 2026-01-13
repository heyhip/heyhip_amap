class HeyhipMarkerPopup {
  final String title;
  final String? subtitle;
  final String? avatarUrl;

  const HeyhipMarkerPopup({
    required this.title,
    this.subtitle,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'avatarUrl': avatarUrl,
    };
  }
}
