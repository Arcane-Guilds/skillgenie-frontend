class Course {
  final String id;
  final String userId;
  final String quizResultId;
  final String title;
  final CourseContent content;
  final int currentLevel;
  final Map<String, int> progress;
  final String createdAt;
  final String updatedAt;

  Course({
    required this.id,
    required this.userId,
    required this.quizResultId,
    required this.title,
    required this.content,
    required this.currentLevel,
    required this.progress,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      quizResultId: json['quizResultId'] ?? '',
      title: json['title'] ?? '',
      content: CourseContent.fromJson(json['content'] ?? {}),
      currentLevel: json['currentLevel'] ?? 0,
      progress: Map<String, int>.from(json['progress'] ?? {}),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'quizResultId': quizResultId,
      'title': title,
      'content': content.toJson(),
      'currentLevel': currentLevel,
      'progress': progress,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class CourseContent {
  final String overview;
  final CourseStory story;
  final LearningPath? learningPath;
  final List<CourseLevel> levels;
  final GameElements? gameElements;

  CourseContent({
    required this.overview,
    required this.story,
    this.learningPath,
    required this.levels,
    this.gameElements,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    // Parse the main levels
    final List<CourseLevel> mainLevels = (json['levels'] as List<dynamic>?)
            ?.map((level) => CourseLevel.fromJson(level))
            .toList() ??
        [];
    
    // Parse learning path levels if they exist
    List<CourseLevel> learningPathLevels = [];
    if (json['learningPath'] != null && json['learningPath']['levels'] is List) {
      // Filter out the "finalProjectRequirementsList" entry if it exists
      final levelsList = (json['learningPath']['levels'] as List).where((item) => item is Map).toList();
      learningPathLevels = levelsList
          .map((level) => CourseLevel.fromJson(level))
          .toList();
    }
    
    // Combine both lists of levels, prioritizing learning path levels
    final List<CourseLevel> allLevels = [...mainLevels];
    
    // Add learning path levels that don't have the same level number as any main level
    for (final lpLevel in learningPathLevels) {
      if (!allLevels.any((level) => level.levelNumber == lpLevel.levelNumber)) {
        allLevels.add(lpLevel);
      }
    }
    
    // Sort levels by level number
    allLevels.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
    
    return CourseContent(
      overview: json['overview'] ?? '',
      story: CourseStory.fromJson(json['story'] ?? {}),
      learningPath: json['learningPath'] != null 
          ? LearningPath.fromJson(json['learningPath']) 
          : null,
      levels: allLevels,
      gameElements: json['gameElements'] != null 
          ? GameElements.fromJson(json['gameElements']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'overview': overview,
      'story': story.toJson(),
      'levels': levels.map((level) => level.toJson()).toList(),
    };
    
    if (learningPath != null) {
      data['learningPath'] = learningPath!.toJson();
    }
    
    if (gameElements != null) {
      data['gameElements'] = gameElements!.toJson();
    }
    
    return data;
  }
}

class LearningPath {
  final List<String> skills;
  final String finalProject;
  final String courseDescription;
  final int coursePrice;

  LearningPath({
    required this.skills,
    required this.finalProject,
    required this.courseDescription,
    required this.coursePrice,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      skills: List<String>.from(json['skills'] ?? []),
      finalProject: json['finalProject'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      coursePrice: json['coursePrice'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skills': skills,
      'finalProject': finalProject,
      'courseDescription': courseDescription,
      'coursePrice': coursePrice,
    };
  }
}

class GameElements {
  final List<String> achievements;
  final String leaderboard;
  final String socialElements;

  GameElements({
    required this.achievements,
    required this.leaderboard,
    required this.socialElements,
  });

  factory GameElements.fromJson(Map<String, dynamic> json) {
    return GameElements(
      achievements: List<String>.from(json['achievements'] ?? []),
      leaderboard: json['leaderboard'] ?? '',
      socialElements: json['socialElements'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievements': achievements,
      'leaderboard': leaderboard,
      'socialElements': socialElements,
    };
  }
}

class CourseStory {
  final String narrative;
  final String world;

  CourseStory({
    required this.narrative,
    required this.world,
  });

  factory CourseStory.fromJson(Map<String, dynamic> json) {
    return CourseStory(
      narrative: json['narrative'] ?? '',
      world: json['world'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'narrative': narrative,
      'world': world,
    };
  }
}

class CourseLevel {
  final int levelNumber;
  final String title;
  final List<String> objectives;
  final String narrative;
  final List<CourseChapter> chapters;
  final CourseReward? rewards;
  final BonusContent? bonusContent;

  CourseLevel({
    required this.levelNumber,
    required this.title,
    required this.objectives,
    required this.narrative,
    required this.chapters,
    this.rewards,
    this.bonusContent,
  });

  factory CourseLevel.fromJson(Map<String, dynamic> json) {
    return CourseLevel(
      levelNumber: json['levelNumber'] ?? 0,
      title: json['title'] ?? '',
      objectives: List<String>.from(json['objectives'] ?? []),
      narrative: json['narrative'] ?? '',
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((chapter) => CourseChapter.fromJson(chapter))
              .toList() ??
          [],
      rewards: json['rewards'] != null ? CourseReward.fromJson(json['rewards']) : null,
      bonusContent: json['bonusContent'] != null ? BonusContent.fromJson(json['bonusContent']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'levelNumber': levelNumber,
      'title': title,
      'objectives': objectives,
      'narrative': narrative,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
    
    if (rewards != null) {
      data['rewards'] = rewards!.toJson();
    }
    
    if (bonusContent != null) {
      data['bonusContent'] = bonusContent!.toJson();
    }
    
    return data;
  }
}

class BonusContent {
  final String funFact;
  final String advancedConcept;

  BonusContent({
    required this.funFact,
    required this.advancedConcept,
  });

  factory BonusContent.fromJson(Map<String, dynamic> json) {
    return BonusContent(
      funFact: json['funFact'] ?? '',
      advancedConcept: json['advancedConcept'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'funFact': funFact,
      'advancedConcept': advancedConcept,
    };
  }
}

class CourseChapter {
  final String title;
  final String story;
  final String conceptIntroduction;
  final String realWorldApplication;
  final List<CourseExercise> exercises;
  final ChapterChallenge? challenge;
  final ChapterRewards? rewards;
  final ConceptExplanation? conceptExplanation;
  final TutorialContent? tutorialContent;
  final AdditionalResources? additionalResources;

  CourseChapter({
    required this.title,
    required this.story,
    this.conceptIntroduction = '',
    this.realWorldApplication = '',
    required this.exercises,
    this.challenge,
    this.rewards,
    this.conceptExplanation,
    this.tutorialContent,
    this.additionalResources,
  });

  factory CourseChapter.fromJson(Map<String, dynamic> json) {
    return CourseChapter(
      title: json['title'] ?? '',
      story: json['story'] ?? '',
      conceptIntroduction: json['conceptIntroduction'] ?? '',
      realWorldApplication: json['realWorldApplication'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((exercise) => CourseExercise.fromJson(exercise))
              .toList() ??
          [],
      challenge: json['challenge'] != null ? ChapterChallenge.fromJson(json['challenge']) : null,
      rewards: json['rewards'] != null ? ChapterRewards.fromJson(json['rewards']) : null,
      conceptExplanation: json['conceptExplanation'] != null 
          ? ConceptExplanation.fromJson(json['conceptExplanation']) 
          : null,
      tutorialContent: json['tutorialContent'] != null 
          ? TutorialContent.fromJson(json['tutorialContent']) 
          : null,
      additionalResources: json['additionalResources'] != null 
          ? AdditionalResources.fromJson(json['additionalResources']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'story': story,
      'conceptIntroduction': conceptIntroduction,
      'realWorldApplication': realWorldApplication,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
    
    if (challenge != null) {
      data['challenge'] = challenge!.toJson();
    }
    
    if (rewards != null) {
      data['rewards'] = rewards!.toJson();
    }
    
    if (conceptExplanation != null) {
      data['conceptExplanation'] = conceptExplanation!.toJson();
    }
    
    if (tutorialContent != null) {
      data['tutorialContent'] = tutorialContent!.toJson();
    }
    
    if (additionalResources != null) {
      data['additionalResources'] = additionalResources!.toJson();
    }
    
    return data;
  }
}

class ConceptExplanation {
  final String basicDefinition;
  final String detailedExplanation;
  final List<String> codeExamples;
  final List<String> commonMistakes;
  final List<String> bestPractices;

  ConceptExplanation({
    required this.basicDefinition,
    required this.detailedExplanation,
    required this.codeExamples,
    required this.commonMistakes,
    required this.bestPractices,
  });

  factory ConceptExplanation.fromJson(Map<String, dynamic> json) {
    return ConceptExplanation(
      basicDefinition: json['basicDefinition'] ?? '',
      detailedExplanation: json['detailedExplanation'] ?? '',
      codeExamples: List<String>.from(json['codeExamples'] ?? []),
      commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
      bestPractices: List<String>.from(json['bestPractices'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basicDefinition': basicDefinition,
      'detailedExplanation': detailedExplanation,
      'codeExamples': codeExamples,
      'commonMistakes': commonMistakes,
      'bestPractices': bestPractices,
    };
  }
}

class TutorialContent {
  final List<TutorialStep> steps;

  TutorialContent({
    required this.steps,
  });

  factory TutorialContent.fromJson(Map<String, dynamic> json) {
    return TutorialContent(
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => TutorialStep.fromJson(step))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }
}

class TutorialStep {
  final String title;
  final String explanation;
  final String codeSnippet;
  final String expectedOutput;

  TutorialStep({
    required this.title,
    required this.explanation,
    required this.codeSnippet,
    required this.expectedOutput,
  });

  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    return TutorialStep(
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      codeSnippet: json['codeSnippet'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'explanation': explanation,
      'codeSnippet': codeSnippet,
      'expectedOutput': expectedOutput,
    };
  }
}

class AdditionalResources {
  final List<String> readings;
  final List<String> videos;
  final List<String> exercises;

  AdditionalResources({
    required this.readings,
    required this.videos,
    required this.exercises,
  });

  factory AdditionalResources.fromJson(Map<String, dynamic> json) {
    return AdditionalResources(
      readings: List<String>.from(json['readings'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      exercises: List<String>.from(json['exercises'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'readings': readings,
      'videos': videos,
      'exercises': exercises,
    };
  }
}

class CourseExercise {
  final String type;
  final String content;
  final String solution;
  final List<String> hints;
  final String successMessage;
  final String failureHint;
  final String explanation;

  CourseExercise({
    required this.type,
    required this.content,
    required this.solution,
    required this.hints,
    this.successMessage = '',
    this.failureHint = '',
    this.explanation = '',
  });

  factory CourseExercise.fromJson(Map<String, dynamic> json) {
    return CourseExercise(
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      solution: json['solution'] ?? '',
      hints: List<String>.from(json['hints'] ?? []),
      successMessage: json['successMessage'] ?? '',
      failureHint: json['failureHint'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'solution': solution,
      'hints': hints,
      'successMessage': successMessage,
      'failureHint': failureHint,
      'explanation': explanation,
    };
  }
}

class ChapterChallenge {
  final String scenario;
  final List<String> requirements;
  final String starterCode;
  final List<String> testCases;

  ChapterChallenge({
    required this.scenario,
    required this.requirements,
    required this.starterCode,
    required this.testCases,
  });

  factory ChapterChallenge.fromJson(Map<String, dynamic> json) {
    return ChapterChallenge(
      scenario: json['scenario'] ?? '',
      requirements: List<String>.from(json['requirements'] ?? []),
      starterCode: json['starterCode'] ?? '',
      testCases: List<String>.from(json['testCases'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenario': scenario,
      'requirements': requirements,
      'starterCode': starterCode,
      'testCases': testCases,
    };
  }
}

class ChapterRewards {
  final String badge;
  final String badgeDescription;
  final String unlocks;

  ChapterRewards({
    required this.badge,
    required this.badgeDescription,
    required this.unlocks,
  });

  factory ChapterRewards.fromJson(Map<String, dynamic> json) {
    return ChapterRewards(
      badge: json['badge'] ?? '',
      badgeDescription: json['badgeDescription'] ?? '',
      unlocks: json['unlocks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge': badge,
      'badgeDescription': badgeDescription,
      'unlocks': unlocks,
    };
  }
}

class CourseReward {
  final String badge;
  final String badgeDescription;
  final dynamic unlocks;
  final String xpPoints;

  CourseReward({
    required this.badge,
    this.badgeDescription = '',
    required this.unlocks,
    this.xpPoints = '',
  });

  factory CourseReward.fromJson(Map<String, dynamic> json) {
    return CourseReward(
      badge: json['badge'] ?? '',
      badgeDescription: json['badgeDescription'] ?? '',
      unlocks: json['unlocks'] ?? '',
      xpPoints: json['xpPoints'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'badge': badge,
      'badgeDescription': badgeDescription,
      'unlocks': unlocks,
      'xpPoints': xpPoints,
    };
  }
}