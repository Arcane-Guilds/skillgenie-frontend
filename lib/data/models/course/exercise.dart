enum ExerciseType {
  video,
  interactive,
  project,
  quiz,
  coding,
  reading,
}

class Exercise {
  final int exerciseNumber;
  final String title;
  final String description;
  final ExerciseType type;
  final bool isCompleted;
  final int points;
  final int duration;
  final bool isUnlocked;

  Exercise({
    required this.exerciseNumber,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
    this.points = 10,
    this.duration = 5,
    this.isUnlocked = true,
  });
} 