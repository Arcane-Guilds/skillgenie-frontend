import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skillGenie/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import 'challenges_screen.dart';

class JoinPartyScreen extends StatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
  final TextEditingController _partyCodeController = TextEditingController();
  String? _errorMessage;
  bool isLoading = false;

  Future<void> _joinParty() async {
    final partyCode = _partyCodeController.text.trim();
    if (partyCode.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code de fête';
      });
      return;
    }

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Utilisateur non authentifié';
        isLoading = false;
      });
      return;
    }

    try {
      // Step 1: Join the party
      print('Sending POST /party-code/join with code: $partyCode, userId: $userId');
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/party-code/join'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': partyCode,
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(response.body);
      print('Join party response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 201 && responseData['success'] == true) {
        // Step 2: Fetch party data to get challengeId with retry
        int retries = 3;
        while (retries > 0) {
          print('Sending GET /party-code/$partyCode (attempt ${4 - retries}/3)');
          final partyResponse = await http
              .get(Uri.parse('${ApiConstants.baseUrl}/party-code/$partyCode'))
              .timeout(const Duration(seconds: 5));

          print('Party response: status=${partyResponse.statusCode}, body=${partyResponse.body}');

          if (partyResponse.statusCode == 200) {
            final partyData = jsonDecode(partyResponse.body);
            final challengeId = partyData['challengeId'];
            if (challengeId == null) {
              setState(() {
                _errorMessage = 'Aucun défi associé à ce code de fête';
                isLoading = false;
              });
              return;
            }

            print('Navigating to ChallengesScreen with partyCode: $partyCode, challengeId: $challengeId');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChallengesScreen(
                  partyCode: partyCode,
                  challengeId: challengeId,
                ),
              ),
            );
            return;
          } else {
            retries--;
            if (retries == 0) {
              setState(() {
                _errorMessage = 'Erreur lors de la récupération des données de la fête: ${partyResponse.body}';
                isLoading = false;
              });
              return;
            }
            await Future.delayed(const Duration(seconds: 1)); // Wait before retry
          }
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Échec de la jointure de la fête';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur réseau : ${e.toString()}';
        isLoading = false;
      });
      print('Error joining party: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Rejoindre une fête'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _partyCodeController,
              decoration: InputDecoration(
                labelText: 'Code de la fête',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                errorText: _errorMessage,
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : ElevatedButton(
                    onPressed: _joinParty,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Rejoindre la fête',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _partyCodeController.dispose();
    super.dispose();
  }
}