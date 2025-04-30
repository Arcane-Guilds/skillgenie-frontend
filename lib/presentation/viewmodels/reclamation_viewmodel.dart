import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../data/models/reclamation_model.dart';
import 'auth/auth_viewmodel.dart';

class ReclamationViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  final List<Reclamation> _reclamations = [];
  bool _isLoading = false;
  String? _error;
  bool _isSuccess = false; // Properly declared here

  ReclamationViewModel(this._authViewModel);

  List<Reclamation> get reclamations => _reclamations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSuccess => _isSuccess; // Getter for _isSuccess

  Future<void> submitReclamation(String subject, String message) async {
    if (_isLoading) return; // Prevent multiple submissions

    _isLoading = true;
    _error = null;
    _isSuccess = false; // Now properly referencing the declared variable
    notifyListeners();

    try {
      final userId = _authViewModel.currentUser?.id;
      final token = _authViewModel.tokens?.accessToken;

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final uri = Uri.parse('${ApiConstants.baseUrl}/reclamations');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'subject': subject.trim(),
          'message': message.trim(),
          'status': 'pending',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      if (response.statusCode == 201) {
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic>) {
            final newReclamation = Reclamation.fromJson(responseBody);
            _reclamations.add(newReclamation);
            _isSuccess = true; // Now properly referencing the declared variable
            _error = null;
          } else {
            throw Exception('Invalid response format');
          }
        } catch (e) {
          throw Exception('Failed to parse response: ${e.toString()}');
        }
      } else {
        throw Exception('Failed to submit reclamation: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _isSuccess = false; // Now properly referencing the declared variable
      debugPrint('Error submitting reclamation: $_error');
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
}
