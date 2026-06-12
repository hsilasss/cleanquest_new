import 'user_mission.dart'; // Import UserMission model

class User {
  final int id;
  String username;
  String email;
  final int points;
  String phoneNumber;
  DateTime birthDate;
  final List<UserMission> missions;
  String? profilePicture; // <<< TAMBAHKAN INI

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.points,
    required this.phoneNumber,
    required this.birthDate,
    this.missions = const [],
    this.profilePicture, // <<< TAMBAHKAN INI DI CONSTRUCTOR
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<UserMission> userMissions = [];
    if (json['user_missions'] != null) {
      userMissions = (json['user_missions'] as List)
          .map((e) => UserMission.fromJson(e))
          .toList();
    }

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      points: json['points'],
      phoneNumber: json['phone_number'],
      birthDate: DateTime.parse(json['birth_date']),
      missions: userMissions,
      profilePicture: json['profile_picture'], // <<< TAMBAHKAN INI DI FROMJSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'points': points,
      'phone_number': phoneNumber,
      'birth_date': birthDate.toIso8601String().split('T')[0],
      'user_missions': missions.map((m) => m.toJson()).toList(),
      'profile_picture': profilePicture, // <<< TAMBAHKAN INI DI TOJSON (Opsional jika Anda tidak mengirimnya balik)
    };
  }
}