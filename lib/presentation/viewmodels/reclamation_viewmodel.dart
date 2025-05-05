import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../data/models/reclamation_model.dart';
import '../../core/services/reclamation_socket_service.dart';
import '../../core/services/notification_service.dart';
import 'auth/auth_viewmodel.dart';

class ReclamationViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  final ReclamationSocketService _socketService;
  final http.Client _client;
  final NotificationService _notificationService;
  List<Reclamation> _reclamations = [];
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false;

  ReclamationViewModel(
    this._authViewModel,
    this._socketService,
    this._client,
    this._notificationService,
  ) {
    _initializeSocketService();
  }

  List<Reclamation> get reclamations => _reclamations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSuccess => _isSuccess;

  Future<void> _initializeSocketService() async {
    _socketService.onReclamationUpdate = _handleReclamationUpdate;
    await _socketService.initialize();
  }

  void _handleReclamationUpdate(Reclamation updatedReclamation) {
    final index =
        _reclamations.indexWhere((r) => r.id == updatedReclamation.id);
    final existingReclamation = index != -1 ? _reclamations[index] : null;

    if (index != -1) {
      _reclamations[index] = updatedReclamation;
      // Show notification if admin response was added or changed
      if (existingReclamation?.adminResponse !=
              updatedReclamation.adminResponse &&
          updatedReclamation.adminResponse != null) {
        _showAdminResponseNotification(updatedReclamation);
      }
    } else {
      _reclamations.add(updatedReclamation);
    }
    notifyListeners();
  }

  void _showAdminResponseNotification(Reclamation reclamation) {
    _notificationService.showLocalNotification(
      title: 'Admin Response to Your Reclamation',
      body: reclamation.adminResponse ?? '',
      payload: reclamation.id,
    );
  }

  Future<void> submitReclamation(String subject, String message) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    try {
      final token = _authViewModel.tokens?.accessToken;

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/reclamations');
      debugPrint('Submitting to URL: $uri');

      final requestBody = {
        'subject': subject.trim(),
        'message': message.trim(),
      };

      debugPrint('Request body: ${jsonEncode(requestBody)}');

      final response = await _client
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is Map<String, dynamic>) {
          final newReclamation = Reclamation.fromJson(responseBody);
          _reclamations.add(newReclamation);
          _isSuccess = true;
          _error = null;
          debugPrint('Reclamation submitted successfully');
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to submit reclamation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _error = e.toString();
      _isSuccess = false;
      debugPrint('Error submitting reclamation: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String reclamationId) async {
    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/reclamations/$reclamationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _reclamations.indexWhere((r) => r.id == reclamationId);
        if (index != -1) {
          final updatedReclamation = Reclamation.fromJson({
            ..._reclamations[index].toJson(),
            'isRead': true,
          });
          _reclamations[index] = updatedReclamation;
          notifyListeners();
        }
      } else {
        throw Exception('Failed to mark reclamation as read');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadReclamations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _authViewModel.tokens?.accessToken;
      if (token == null) throw Exception('Not authenticated');

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/reclamations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _reclamations = data.map((json) => Reclamation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reclamations');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetState() {
    _isLoading = false;
    _error = null;
    _isSuccess = false; // Now properly referencing the declared variable
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}
