import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'reclamation_model.g.dart';

@JsonSerializable()
class Reclamation {
  final String? id;
  final String? userId;
  final String? subject;
  final String? message;
  final String status;
  final String? adminResponse;
  final String? handledById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  @JsonKey(defaultValue: false)
  final bool isRead;

  @JsonKey(ignore: true)
  final User? user;
  @JsonKey(ignore: true)
  final User? handledBy;

  Reclamation({
    this.id,
    this.userId,
    this.subject,
    this.message,
    this.status = 'pending',
    this.adminResponse,
    this.handledById,
    this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.user,
    this.handledBy,
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) {
    final reclamation = _$ReclamationFromJson(json);

    // Handle populated user and handledBy fields from backend
    final userJson = json['user'];
    final handledByJson = json['handledBy'];

    return Reclamation(
      id: reclamation.id,
      userId: reclamation.userId,
      subject: reclamation.subject,
      message: reclamation.message,
      status: reclamation.status,
      adminResponse: reclamation.adminResponse,
      handledById: reclamation.handledById,
      createdAt: reclamation.createdAt,
      updatedAt: reclamation.updatedAt,
      isRead: reclamation.isRead,
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
      handledBy: handledByJson is Map<String, dynamic>
          ? User.fromJson(handledByJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$ReclamationToJson(this);
}
