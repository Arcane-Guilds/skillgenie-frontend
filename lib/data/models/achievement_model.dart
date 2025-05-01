class Achievement {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int maxLevel;
  final List<String> levelDescriptions;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.maxLevel,
    required this.levelDescriptions,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      maxLevel: json['maxLevel'] ?? 1,
      levelDescriptions: List<String>.from(json['levelDescriptions'] ?? []),
    );
  }
}
