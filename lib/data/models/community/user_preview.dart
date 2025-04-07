class UserPreview {
  final String id;
  final String username;
  final String? avatar;

  UserPreview({
    required this.id,
    required this.username,
    this.avatar,
  });

  factory UserPreview.fromJson(Map<String, dynamic> json) {
    // Debug the JSON payload
    print('Parsing UserPreview JSON: $json');
    
    try {
      String id = '';
      String username = 'Unknown User';
      String? avatar;
      
      // Parse ID safely
      if (json.containsKey('_id')) {
        id = json['_id']?.toString() ?? '';
      } else if (json.containsKey('id')) {
        // Some APIs might use 'id' instead of '_id'
        id = json['id']?.toString() ?? '';
      }
      
      // Parse username safely
      if (json.containsKey('username')) {
        username = json['username']?.toString() ?? 'Unknown User';
      } else if (json.containsKey('name')) {
        // Some APIs might use 'name' instead of 'username'
        username = json['name']?.toString() ?? 'Unknown User';
      }
      
      // Parse avatar safely
      if (json.containsKey('avatar') && json['avatar'] != null) {
        avatar = json['avatar'].toString();
      }
      
      return UserPreview(
        id: id,
        username: username,
        avatar: avatar,
      );
    } catch (e) {
      print('Error parsing UserPreview from JSON: $e');
      return UserPreview(
        id: '',
        username: 'Unknown User',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'avatar': avatar,
    };
  }
} 