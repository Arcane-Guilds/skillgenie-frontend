import 'package:flutter/material.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/models/user_achievement_model.dart';
import 'package:provider/provider.dart';

class AchievementsScreen extends StatefulWidget {
  final String userId;
  const AchievementsScreen({super.key, required this.userId});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<List<UserAchievement>> _futureAchievements;

  @override
  void initState() {
    super.initState();
    final repository = Provider.of<AchievementRepository>(context, listen: false);
    _futureAchievements = repository.fetchUserAchievements(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<UserAchievement>>(
        future: _futureAchievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No achievements yet.'));
          }
          final achievements = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final userAchievement = achievements[index];
              final achievement = userAchievement.achievement;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
                  title: Text(achievement.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(achievement.description),
                      const SizedBox(height: 4),
                      Text('Level: ${userAchievement.level} / ${achievement.maxLevel}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (achievement.levelDescriptions.isNotEmpty)
                        Text('• ${achievement.levelDescriptions[userAchievement.level - 1]}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                  trailing: userAchievement.level == achievement.maxLevel
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 