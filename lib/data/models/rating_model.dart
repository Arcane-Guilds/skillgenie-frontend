import 'package:json_annotation/json_annotation.dart';

part 'rating_model.g.dart';

@JsonSerializable()
class Rating {
  @JsonKey(name: '_id')
  final String? id;
  final int stars;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rating({
    this.id,
    required this.stars,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);
  Map<String, dynamic> toJson() => _$RatingToJson(this);

  static RatingResponse fromJsonResponse(Map<String, dynamic> json) {
    final List<Rating> ratings = [];
    if (json['ratings'] != null) {
      ratings.addAll((json['ratings'] as List<dynamic>)
          .map((item) => Rating.fromJson(item as Map<String, dynamic>)));
    }

    double avgRating = 0.0;
    if (json['averageRating'] != null) {
      avgRating = (json['averageRating'] as num).toDouble();
    } else if (ratings.isNotEmpty) {
      // Calculate average if not provided
      avgRating = ratings.fold<double>(0, (sum, rating) => sum + rating.stars) /
          ratings.length;
    }

    return RatingResponse(
      ratings: ratings,
      averageRating: avgRating,
    );
  }
}

class RatingResponse {
  final List<Rating> ratings;
  final double averageRating;

  RatingResponse({required this.ratings, required this.averageRating});
}
