import 'package:skillGenie/data/models/course/chapter.dart';

class Level {
  final int levelNumber;
  final String title;
  final String narrative;
  final List<Chapter> chapters;

  Level({
    required this.levelNumber,
    required this.title,
    required this.narrative,
    required this.chapters,
  });
} 