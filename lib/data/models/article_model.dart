class Article {
  final int id;
  final String title;
  final String description;
  final String coverImage;
  final String url;
  final String publishedAt;
  final String readingTimeMinutes;
  final String authorName;
  final String authorImage;
  final List<String> tags;

  Article({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.url,
    required this.publishedAt,
    required this.readingTimeMinutes,
    required this.authorName,
    required this.authorImage,
    required this.tags,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      coverImage: json['cover_image'] as String? ?? '',
      url: json['url'] as String,
      publishedAt: json['published_at'] as String,
      readingTimeMinutes: json['reading_time_minutes'].toString(),
      authorName: json['user']['name'] as String,
      authorImage: json['user']['profile_image'] as String,
      tags: (json['tag_list'] as List<dynamic>).map((tag) => tag.toString()).toList(),
    );
  }
} 