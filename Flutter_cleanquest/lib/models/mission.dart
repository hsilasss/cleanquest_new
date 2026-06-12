class Mission {
  final int id;
  final String title;
  final String? description;
  final int points;
  final String? imageUrl;
  final DateTime tanggalAktif;

  Mission({
    required this.id,
    required this.title,
    this.description,
    required this.points,
    this.imageUrl,
    required this.tanggalAktif,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      points: json['points'],
      imageUrl: json['image_url'],
      tanggalAktif: DateTime.parse(json['tanggal_aktif']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'image_url': imageUrl,
      'tanggal_aktif': tanggalAktif.toIso8601String().split('T')[0],
    };
  }
}