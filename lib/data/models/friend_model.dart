import 'dart:convert';
import 'user_model.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected
}

class FriendRequest {
  final String id;
  final User sender;
  final User receiver;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    User parseSender() {
      final sender = json['sender'];
      if (sender is Map<String, dynamic>) {
        return User.fromJson(sender);
      } else if (sender is String) {
        return User(id: sender, username: '', email: '');
      } else {
        print('Invalid sender format: $sender');
        return User(id: 'unknown', username: 'Unknown User', email: '');
      }
    }

    User parseReceiver() {
      final receiver = json['receiver'];
      if (receiver is Map<String, dynamic>) {
        return User.fromJson(receiver);
      } else if (receiver is String) {
        return User(id: receiver, username: '', email: '');
      } else {
        print('Invalid receiver format: $receiver');
        return User(id: 'unknown', username: 'Unknown User', email: '');
      }
    }

    try {
      return FriendRequest(
        id: json['_id'] ?? json['id'] ?? '',
        sender: parseSender(),
        receiver: parseReceiver(),
        status: _statusFromString(json['status'] ?? 'pending'),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing FriendRequest: $e');
      print('JSON data: $json');
      // Return a placeholder request in case of error
      return FriendRequest(
        id: json['_id'] ?? json['id'] ?? 'error',
        sender: User(id: 'error', username: 'Error', email: ''),
        receiver: User(id: 'error', username: 'Error', email: ''),
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );
    }
  }

  static FriendRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FriendRequestStatus.pending;
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      default:
        return FriendRequestStatus.pending;
    }
  }

  static String _statusToString(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return 'pending';
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.rejected:
        return 'rejected';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.id,
      'receiver': receiver.id,
      'status': _statusToString(status),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<FriendRequest> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => FriendRequest.fromJson(json)).toList();
  }
}

class FriendRequests {
  final List<FriendRequest> sent;
  final List<FriendRequest> received;

  FriendRequests({
    required this.sent,
    required this.received,
  });

  factory FriendRequests.fromJson(Map<String, dynamic> json) {
    return FriendRequests(
      sent: FriendRequest.listFromJson(json['sent'] ?? []),
      received: FriendRequest.listFromJson(json['received'] ?? []),
    );
  }
} 