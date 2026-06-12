class Voucher {
  final int id;
  final String title;
  final String imagePath;
  final int points;

  Voucher({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.points,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      title: json['title'],
      imagePath: json['image_path'],
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_path': imagePath,
      'points': points,
    };
  }
}

