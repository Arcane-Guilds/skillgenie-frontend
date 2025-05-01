import 'achievement_model.dart';

class UserAchievement {
  final String id;
  final Achievement achievement;
  final int level;
  final DateTime earnedAt;

  UserAchievement({
    required this.id,
    required this.achievement,
    required this.level,
    required this.earnedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['_id'] ?? '',
      achievement: Achievement.fromJson(json['achievement']),
      level: json['level'] ?? 1,
      earnedAt: DateTime.parse(json['earnedAt']),
    );
  }
}
