import 'mission.dart';

class UserMission {
  final int id;
  final int userId;
  final int missionId;
  String? proof;
  String status;
  final Mission? mission;
  final DateTime? createdAt; 

  UserMission({
    required this.id,
    required this.userId,
    required this.missionId,
    this.proof,
    required this.status,
    this.mission,
    this.createdAt, 
  });

  factory UserMission.fromJson(Map<String, dynamic> json) {
    return UserMission(
      id: json['id'],
      userId: json['user_id'],
      missionId: json['mission_id'],
      proof: json['proof'],
      status: json['status'],
      mission: json['mission'] != null ? Mission.fromJson(json['mission']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null, // Tambahkan ini
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mission_id': missionId,
      'proof': proof,
      'status': status,
      'mission': mission?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
