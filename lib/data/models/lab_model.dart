
class Lab {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String chapterId;
  final LabRequirements requirements;
  final LabContent content;
  final StarterCode starterCode;
  final List<TestCase> testCases;
  final List<Hint> hints;
  final LabProgression progression;
  final LabRewards rewards;
  final List<String> supportedLanguages;
  final LabResources resources;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lab({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.chapterId,
    required this.requirements,
    required this.content,
    required this.starterCode,
    required this.testCases,
    required this.hints,
    required this.progression,
    required this.rewards,
    required this.supportedLanguages,
    required this.resources,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Lab.fromJson(Map<String, dynamic> json) {
    return Lab(
      id: json['_id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      chapterId: json['chapterId'] ?? '',
      requirements: LabRequirements.fromJson(json['requirements'] ?? {}),
      content: LabContent.fromJson(json['content'] ?? {}),
      starterCode: StarterCode.fromJson(json['starterCode'] ?? {}),
      testCases: (json['testCases'] as List<dynamic>?)
              ?.map((testCase) => TestCase.fromJson(testCase))
              .toList() ??
          [],
      hints: (json['hints'] as List<dynamic>?)
              ?.map((hint) => Hint.fromJson(hint))
              .toList() ??
          [],
      progression: LabProgression.fromJson(json['progression'] ?? {}),
      rewards: LabRewards.fromJson(json['rewards'] ?? {}),
      supportedLanguages: List<String>.from(json['supportedLanguages'] ?? []),
      resources: LabResources.fromJson(json['resources'] ?? {}),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'chapterId': chapterId,
      'requirements': requirements.toJson(),
      'content': content.toJson(),
      'starterCode': starterCode.toJson(),
      'testCases': testCases.map((testCase) => testCase.toJson()).toList(),
      'hints': hints.map((hint) => hint.toJson()).toList(),
      'progression': progression.toJson(),
      'rewards': rewards.toJson(),
      'supportedLanguages': supportedLanguages,
      'resources': resources.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class LabRequirements {
  final List<String> objectives;
  final List<String> acceptanceCriteria;
  final List<String> prerequisites;
  final String difficulty;
  final String estimatedTime;

  LabRequirements({
    required this.objectives,
    required this.acceptanceCriteria,
    required this.prerequisites,
    required this.difficulty,
    required this.estimatedTime,
  });

  factory LabRequirements.fromJson(Map<String, dynamic> json) {
    return LabRequirements(
      objectives: List<String>.from(json['objectives'] ?? []),
      acceptanceCriteria: List<String>.from(json['acceptanceCriteria'] ?? []),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      difficulty: json['difficulty'] ?? 'beginner',
      estimatedTime: json['estimatedTime'] ?? '30 minutes',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectives': objectives,
      'acceptanceCriteria': acceptanceCriteria,
      'prerequisites': prerequisites,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime,
    };
  }
}

class LabContent {
  final String introduction;
  final String conceptExplanation;
  final List<StepByStep> stepByStep;

  LabContent({
    required this.introduction,
    required this.conceptExplanation,
    required this.stepByStep,
  });

  factory LabContent.fromJson(Map<String, dynamic> json) {
    return LabContent(
      introduction: json['introduction'] ?? '',
      conceptExplanation: json['conceptExplanation'] ?? '',
      stepByStep: (json['stepByStep'] as List<dynamic>?)
              ?.map((step) => StepByStep.fromJson(step))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'introduction': introduction,
      'conceptExplanation': conceptExplanation,
      'stepByStep': stepByStep.map((step) => step.toJson()).toList(),
    };
  }
}

class StepByStep {
  final String title;
  final String explanation;
  final String codeExample;
  final List<String> tips;

  StepByStep({
    required this.title,
    required this.explanation,
    required this.codeExample,
    required this.tips,
  });

  factory StepByStep.fromJson(Map<String, dynamic> json) {
    return StepByStep(
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      codeExample: json['codeExample'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'explanation': explanation,
      'codeExample': codeExample,
      'tips': tips,
    };
  }
}

class StarterCode {
  final String code;
  final String language;
  final String? framework;
  final List<String> dependencies;

  StarterCode({
    required this.code,
    required this.language,
    this.framework,
    required this.dependencies,
  });

  factory StarterCode.fromJson(Map<String, dynamic> json) {
    return StarterCode(
      code: json['code'] ?? '',
      language: json['language'] ?? 'javascript',
      framework: json['framework'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'language': language,
      'framework': framework,
      'dependencies': dependencies,
    };
  }
}

class TestCase {
  final String description;
  final String input;
  final String expectedOutput;
  final bool isHidden;

  TestCase({
    required this.description,
    required this.input,
    required this.expectedOutput,
    required this.isHidden,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      description: json['description'] ?? '',
      input: json['input'] ?? '',
      expectedOutput: json['expectedOutput'] ?? '',
      isHidden: json['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'input': input,
      'expectedOutput': expectedOutput,
      'isHidden': isHidden,
    };
  }
}

class Hint {
  final String content;
  final int coinCost;
  final bool unlocked;

  Hint({
    required this.content,
    required this.coinCost,
    required this.unlocked,
  });

  factory Hint.fromJson(Map<String, dynamic> json) {
    return Hint(
      content: json['content'] ?? '',
      coinCost: json['coinCost'] ?? 0,
      unlocked: json['unlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'coinCost': coinCost,
      'unlocked': unlocked,
    };
  }
}

class LabProgression {
  final int requiredCompletionRate;
  final UnlockRequirements unlockRequirements;

  LabProgression({
    required this.requiredCompletionRate,
    required this.unlockRequirements,
  });

  factory LabProgression.fromJson(Map<String, dynamic> json) {
    return LabProgression(
      requiredCompletionRate: json['requiredCompletionRate'] ?? 100,
      unlockRequirements: UnlockRequirements.fromJson(
          json['unlockRequirements'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiredCompletionRate': requiredCompletionRate,
      'unlockRequirements': unlockRequirements.toJson(),
    };
  }
}

class UnlockRequirements {
  final int requiredChapterProgress;
  final List<String>? previousLabIds;
  final int? requiredCoins;

  UnlockRequirements({
    required this.requiredChapterProgress,
    this.previousLabIds,
    this.requiredCoins,
  });

  factory UnlockRequirements.fromJson(Map<String, dynamic> json) {
    return UnlockRequirements(
      requiredChapterProgress: json['requiredChapterProgress'] ?? 0,
      previousLabIds: json['previousLabIds'] != null
          ? List<String>.from(json['previousLabIds'])
          : null,
      requiredCoins: json['requiredCoins'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiredChapterProgress': requiredChapterProgress,
      'previousLabIds': previousLabIds,
      'requiredCoins': requiredCoins,
    };
  }
}

class LabRewards {
  final int coins;
  final int xp;

  LabRewards({
    required this.coins,
    required this.xp,
  });

  factory LabRewards.fromJson(Map<String, dynamic> json) {
    return LabRewards(
      coins: json['coins'] ?? 0,
      xp: json['xp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'xp': xp,
    };
  }
}

class LabResources {
  final List<String> documentation;
  final List<String> externalLinks;
  final List<String> videos;

  LabResources({
    required this.documentation,
    required this.externalLinks,
    required this.videos,
  });

  factory LabResources.fromJson(Map<String, dynamic> json) {
    return LabResources(
      documentation: List<String>.from(json['documentation'] ?? []),
      externalLinks: List<String>.from(json['externalLinks'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentation': documentation,
      'externalLinks': externalLinks,
      'videos': videos,
    };
  }
}

class LabSubmission {
  final String id;
  final String userId;
  final String labId;
  final String code;
  final int attempts;
  final List<String> purchasedHints;
  final int coinsSpent;
  final bool isComplete;
  final EvaluationResult? evaluationResult;
  final DateTime createdAt;
  final DateTime updatedAt;

  LabSubmission({
    required this.id,
    required this.userId,
    required this.labId,
    required this.code,
    required this.attempts,
    required this.purchasedHints,
    required this.coinsSpent,
    required this.isComplete,
    this.evaluationResult,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LabSubmission.fromJson(Map<String, dynamic> json) {
    return LabSubmission(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      labId: json['labId'] ?? '',
      code: json['code'] ?? '',
      attempts: json['attempts'] ?? 0,
      purchasedHints: List<String>.from(json['purchasedHints'] ?? []),
      coinsSpent: json['coinsSpent'] ?? 0,
      isComplete: json['isComplete'] ?? false,
      evaluationResult: json['evaluationResult'] != null
          ? EvaluationResult.fromJson(json['evaluationResult'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'labId': labId,
      'code': code,
      'attempts': attempts,
      'purchasedHints': purchasedHints,
      'coinsSpent': coinsSpent,
      'isComplete': isComplete,
      'evaluationResult': evaluationResult?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class EvaluationResult {
  final bool passed;
  final int score;
  final List<String> feedback;
  final List<TestResult> testResults;
  final CodeQuality codeQuality;

  EvaluationResult({
    required this.passed,
    required this.score,
    required this.feedback,
    required this.testResults,
    required this.codeQuality,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      passed: json['passed'] ?? false,
      score: json['score'] ?? 0,
      feedback: List<String>.from(json['feedback'] ?? []),
      testResults: (json['testResults'] as List<dynamic>?)
              ?.map((test) => TestResult.fromJson(test))
              .toList() ??
          [],
      codeQuality: CodeQuality.fromJson(json['codeQuality'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passed': passed,
      'score': score,
      'feedback': feedback,
      'testResults': testResults.map((test) => test.toJson()).toList(),
      'codeQuality': codeQuality.toJson(),
    };
  }
}

class TestResult {
  final bool passed;
  final String testCase;
  final String? error;
  final String? expected;
  final String? actual;

  TestResult({
    required this.passed,
    required this.testCase,
    this.error,
    this.expected,
    this.actual,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      passed: json['passed'] ?? false,
      testCase: json['testCase'] ?? '',
      error: json['error'],
      expected: json['expected'],
      actual: json['actual'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passed': passed,
      'testCase': testCase,
      'error': error,
      'expected': expected,
      'actual': actual,
    };
  }
}

class CodeQuality {
  final double efficiency;
  final double style;
  final List<String> suggestions;
  final List<String> bestPractices;

  CodeQuality({
    required this.efficiency,
    required this.style,
    required this.suggestions,
    required this.bestPractices,
  });

  factory CodeQuality.fromJson(Map<String, dynamic> json) {
    return CodeQuality(
      efficiency: (json['efficiency'] ?? 0).toDouble(),
      style: (json['style'] ?? 0).toDouble(),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      bestPractices: List<String>.from(json['bestPractices'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'efficiency': efficiency,
      'style': style,
      'suggestions': suggestions,
      'bestPractices': bestPractices,
    };
  }
}

class LabSubmitRequest {
  final String userId;
  final String labId;
  final String code;
  final String language;

  LabSubmitRequest({
    required this.userId,
    required this.labId,
    required this.code,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'labId': labId,
      'code': code,
      'language': language,
    };
  }
}

class LabResponse {
  final LabSubmission submission;
  final Lab? nextLab;
  final String? error;  
  final bool success;   

  LabResponse({
    required this.submission,
    this.nextLab,
    this.error,
    required this.success,
  });

  factory LabResponse.fromJson(Map<String, dynamic> json) {
    return LabResponse(
      submission: LabSubmission.fromJson(json['submission'] ?? {}),
      nextLab: json['nextLab'] != null ? Lab.fromJson(json['nextLab']) : null,
      error: json['error'],
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submission': submission.toJson(),
      'nextLab': nextLab?.toJson(),
      'error': error,
      'success': success,
    };
  }
} 