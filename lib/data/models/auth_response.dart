import 'dart:convert';
import 'package:frontend/data/models/tokens.dart';

class AuthResponse {
  final String message;
  final Tokens tokens;
  final String userId;
  final String jwt;

  AuthResponse({required this.message, required this.tokens, required this.userId, required this.jwt});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    String userId = '';
    if (json['tokens'] != null && json['tokens']['accessToken'] != null) {
      final accessToken = json['tokens']['accessToken'];
      final payload = _decodeJwt(accessToken);
      userId = payload['_id'] ?? '';
    }

    return AuthResponse(
      message: json['message'] ?? '',
      tokens: Tokens.fromJson(json['tokens']),
      userId: userId,
      jwt: json['jwt'] ?? '',
    );
  }

  static Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception("Invalid JWT format");

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return jsonDecode(payload);
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'tokens': tokens.toJson(),
      'userId': userId,
      'jwt': jwt,
    };
  }
}