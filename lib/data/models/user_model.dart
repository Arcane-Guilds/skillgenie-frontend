import 'dart:convert';

class User {
  final String id;
  final String username;
  final String email;
  final String? role;
  final String? avatar;
  final String? bio;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.role,
    this.avatar,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'], // Handle both id and _id
      username: json['username'],
      email: json['email'],
      role: json['role'],
      avatar: json['avatar'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'avatar': avatar,
      'bio': bio,
    };
  }

  static User? fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return User.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  String toJsonString() {
    return json.encode(toJson());
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? avatar,
    String? bio,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
    );
  }
}
