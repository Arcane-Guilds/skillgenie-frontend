import 'package:json_annotation/json_annotation.dart';

part 'reclamation_model.g.dart';

@JsonSerializable()
class Reclamation {
  final String? id;
  final String? userId;  // Changed to nullable
  final String? subject; // Changed to nullable
  final String? message; // Changed to nullable
  final String status;
  final String? adminResponse;
  final String? handledBy;
  final DateTime? createdAt; // Changed to nullable
  final DateTime? updatedAt; // Changed to nullable

  Reclamation({
    this.id,
    this.userId,
    this.subject,
    this.message,
    this.status = 'pending',
    this.adminResponse,
    this.handledBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) =>
      _$ReclamationFromJson(json);
  Map<String, dynamic> toJson() => _$ReclamationToJson(this);
}
