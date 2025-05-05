class UserProgress {
  final int totalExercises;
  final int completedExercises;
  final double completionRate;

  UserProgress({
    required this.totalExercises,
    required this.completedExercises,
    required this.completionRate,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    totalExercises: json['totalExercises'] ?? 0,
    completedExercises: json['completedExercises'] ?? 0,
    completionRate: (json['completionRate'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'totalExercises': totalExercises,
    'completedExercises': completedExercises,
    'completionRate': completionRate,
  };
}

class StrengthsWeaknesses {
  final List<String> strengths;
  final List<String> weaknesses;

  StrengthsWeaknesses({
    required this.strengths,
    required this.weaknesses,
  });

  factory StrengthsWeaknesses.fromJson(Map<String, dynamic> json) => StrengthsWeaknesses(
    strengths: List<String>.from(json['strengths'] ?? []),
    weaknesses: List<String>.from(json['weaknesses'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'strengths': strengths,
    'weaknesses': weaknesses,
  };
}

class Engagement {
  final int logins;
  final String lastActive;
  final int timeSpent;
  final int participation;
  final String createdAt;

  Engagement({
    required this.logins,
    required this.lastActive,
    required this.timeSpent,
    required this.participation,
    required this.createdAt,
  });

  factory Engagement.fromJson(Map<String, dynamic> json) => Engagement(
    logins: json['logins'] ?? 0,
    lastActive: json['lastActive'] ?? '',
    timeSpent: json['timeSpent'] ?? 0,
    participation: json['participation'] ?? 0,
    createdAt: json['createdAt'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'logins': logins,
    'lastActive': lastActive,
    'timeSpent': timeSpent,
    'participation': participation,
    'createdAt': createdAt,
  };
}

class Recommendations {
  final List<String> recommendations;

  Recommendations({required this.recommendations});

  factory Recommendations.fromJson(Map<String, dynamic> json) => Recommendations(
    recommendations: List<String>.from(json['recommendations'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'recommendations': recommendations,
  };
}