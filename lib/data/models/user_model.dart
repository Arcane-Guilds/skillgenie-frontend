import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String? role;
  final String? avatar;
  final String? profilePicture;
  final String? bio;
  final int streak;
  final int totalXP;
  final double dailyProgress;
  final int coins;
  final int currentStreak;
  final int bestStreak;
  final DateTime lastActivityDate;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.role,
    this.avatar,
    this.profilePicture,
    this.bio,
    this.streak = 0,
    this.totalXP = 0,
    this.dailyProgress = 0.0,
    this.coins = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    DateTime? lastActivityDate,
  }) : lastActivityDate = lastActivityDate ?? DateTime(0);

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] ?? json['_id'] ?? ''; // Handle both id and _id
      if (id == '') {
        print('Warning: User has no ID: $json');
      }

      // For username and email, provide defaults if missing
      final username = json['username'] ?? 'Unknown User';
      final email = json['email'] ?? 'no-email@example.com';

      // Check for profilePicture in various fields that might contain the image
      String? profilePic = json['profilePicture'] ?? 
                          json['profileImage'] ?? 
                          json['avatar'] ?? 
                          json['profilePic'] ?? 
                          json['image'];

      return User(
        id: id,
        username: username,
        email: email,
        role: json['role'],
        avatar: json['avatar'],
        profilePicture: profilePic,
        bio: json['bio'],
        streak: json['streak'] ?? 0,
        totalXP: json['totalXP'] ?? 0,
        dailyProgress: (json['dailyProgress'] ?? 0.0).toDouble(),
        coins: json['coins'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        bestStreak: json['bestStreak'] ?? 0,
        lastActivityDate: json['lastActivityDate'] != null 
            ? DateTime.parse(json['lastActivityDate'] as String)
            : DateTime(0),
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
      'profilePicture': profilePicture,
      'bio': bio,
      'streak': streak,
      'totalXP': totalXP,
      'dailyProgress': dailyProgress,
      'coins': coins,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastActivityDate': lastActivityDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (avatar != null) 'avatar': avatar,
      if (bio != null) 'bio': bio,
      // Do NOT include id, streak, totalXP, dailyProgress, profilePicture, etc.
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
    String? profilePicture,
    String? bio,
    int? streak,
    int? totalXP,
    double? dailyProgress,
    int? coins,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastActivityDate,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      streak: streak ?? this.streak,
      totalXP: totalXP ?? this.totalXP,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      coins: coins ?? this.coins,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  static Future<bool> updateCoins(String userId) async {
    try {
      final backendUrl = dotenv.env['API_BASE_URL'] ?? '';
      if (backendUrl.isEmpty) {
        print('Error: API URL not configured');
        return false;
      }

      final response = await http.get(
        Uri.parse('$backendUrl/user/$userId/coins'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Coin update response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response to verify the update
        final responseData = json.decode(response.body);
        if (responseData['coins'] != null) {
          print('Coins updated successfully. New balance: ${responseData['coins']}');
          return true;
        } else {
          print('Response did not contain updated coin balance');
          return false;
        }
      } else {
        print('Failed to update coins. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception while updating coins: $e');
      return false;
    }
  }
}
