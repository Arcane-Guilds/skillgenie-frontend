// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reclamation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reclamation _$ReclamationFromJson(Map<String, dynamic> json) => Reclamation(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      subject: json['subject'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminResponse: json['adminResponse'] as String?,
      handledById: json['handledById'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );

Map<String, dynamic> _$ReclamationToJson(Reclamation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'subject': instance.subject,
      'message': instance.message,
      'status': instance.status,
      'adminResponse': instance.adminResponse,
      'handledById': instance.handledById,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isRead': instance.isRead,
    };
