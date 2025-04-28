import 'chapter.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<Chapter> chapters;
  final int totalPoints;
  final int completedPoints;
  final bool isCompleted;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.chapters,
    this.totalPoints = 0,
    this.completedPoints = 0,
    this.isCompleted = false,
  });
} 