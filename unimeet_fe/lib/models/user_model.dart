import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String nim;
  final String major;
  final String batch;
  final String campus;
  final String avatarInitials;
  final String? avatarUrl;
  final bool isVerified;
  final List<String> interests;
  final int meetupsJoined;
  final int hostedCount;
  final double karma;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nim,
    this.major = 'Computer Science',
    this.batch = '2024',
    this.campus = 'BINUS Anggrek Campus',
    required this.avatarInitials,
    this.avatarUrl,
    this.isVerified = true,
    this.interests = const [
      'Badminton Enthusiast',
      'Cafe Hopper',
      'UI/UX & Web Dev',
      'Valorant Gamer',
    ],
    this.meetupsJoined = 1,
    this.hostedCount = 0,
    this.karma = 5.0,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? nim,
    String? major,
    String? batch,
    String? campus,
    String? avatarInitials,
    String? avatarUrl,
    bool? isVerified,
    List<String>? interests,
    int? meetupsJoined,
    int? hostedCount,
    double? karma,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      major: major ?? this.major,
      batch: batch ?? this.batch,
      campus: campus ?? this.campus,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      interests: interests ?? this.interests,
      meetupsJoined: meetupsJoined ?? this.meetupsJoined,
      hostedCount: hostedCount ?? this.hostedCount,
      karma: karma ?? this.karma,
    );
  }

  static String deriveNameFromEmail(String emailPrefix) {
    if (emailPrefix.isEmpty) return 'Binusian Student';
    final parts = emailPrefix.split(RegExp(r'[._-]'));
    return parts.map((p) {
      if (p.isEmpty) return '';
      return p[0].toUpperCase() + p.substring(1).toLowerCase();
    }).join(' ');
  }

  static String extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'ST';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'nim': nim,
      'major': major,
      'batch': batch,
      'campus': campus,
      'avatarInitials': avatarInitials,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'interests': interests,
      'meetupsJoined': meetupsJoined,
      'hostedCount': hostedCount,
      'karma': karma,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Binusian Student',
      email: map['email'] ?? '',
      nim: map['nim'] ?? '',
      major: map['major'] ?? 'Computer Science',
      batch: map['batch'] ?? '2024',
      campus: map['campus'] ?? 'BINUS Anggrek Campus',
      avatarInitials: map['avatarInitials'] ?? 'ST',
      avatarUrl: map['avatarUrl'],
      isVerified: map['isVerified'] ?? true,
      interests: List<String>.from(map['interests'] ?? []),
      meetupsJoined: map['meetupsJoined'] ?? 0,
      hostedCount: map['hostedCount'] ?? 0,
      karma: (map['karma'] is num) ? (map['karma'] as num).toDouble() : 5.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}
