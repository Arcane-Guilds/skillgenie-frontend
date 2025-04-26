import 'exercise.dart';

class Chapter {
  final int chapterNumber;
  final String title;
  final String story;
  final List<Exercise> exercises;

  Chapter({
    required this.chapterNumber,
    required this.title,
    required this.story,
    required this.exercises,
  });
} 