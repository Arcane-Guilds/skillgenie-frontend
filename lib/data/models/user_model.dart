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
    try {
      final id = json['id'] ?? json['_id'] ?? ''; // Handle both id and _id
      if (id == '') {
        print('Warning: User has no ID: $json');
      }

      // For username and email, provide defaults if missing
      final username = json['username'] ?? 'Unknown User';
      final email = json['email'] ?? 'no-email@example.com';

      return User(
        id: id,
        username: username,
        email: email,
        role: json['role'],
        avatar: json['avatar'],
        bio: json['bio'],
      );
    } catch (e) {
      print('Error parsing User JSON: $e');
      print('JSON data: $json');
      // Return a minimal user object with error markers in case of parsing failure
      return User(
        id: json['id'] ?? json['_id'] ?? 'error',
        username: 'Error: ${json['username'] ?? 'Unknown'}',
        email: 'error@example.com',
      );
    }
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
