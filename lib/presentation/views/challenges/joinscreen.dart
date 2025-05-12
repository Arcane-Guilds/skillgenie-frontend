import 'package:flutter/material.dart';
import 'challenges_screen.dart';
import '../../widgets/avatar_widget.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skillGenie/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class JoinPartyScreen extends StatefulWidget {
  const JoinPartyScreen({super.key});

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  String? _errorMessage;
  bool isLoading = false;
  final TextEditingController _partyCodeController = TextEditingController();
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
      print(
          'Sending POST /party-code/join with code: $partyCode, userId: $userId');
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
      print(
          'Join party response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 201 && responseData['success'] == true) {
        // Step 2: Fetch party data to get challengeId with retry
        int retries = 3;
        while (retries > 0) {
          print(
              'Sending GET /party-code/$partyCode (attempt ${4 - retries}/3)');
          final partyResponse = await http
              .get(Uri.parse('${ApiConstants.baseUrl}/party-code/$partyCode'))
              .timeout(const Duration(seconds: 5));

          print(
              'Party response: status=${partyResponse.statusCode}, body=${partyResponse.body}');

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

            print(
                'Navigating to ChallengesScreen with partyCode: $partyCode, challengeId: $challengeId');
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
                _errorMessage =
                    'Erreur lors de la récupération des données de la fête: ${partyResponse.body}';
                isLoading = false;
              });
              return;
            }
            await Future.delayed(
                const Duration(seconds: 1)); // Wait before retry
          }
        }
      } else {
        setState(() {
          _errorMessage =
              responseData['message'] ?? 'Échec de la jointure de la fête';
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
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.1))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideTransition(
                  position: _animation,
                  child: const GenieAvatar(state: AvatarState.idle, size: 120),
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Enter Party Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _partyCodeController,
                          decoration: InputDecoration(
                            hintText: "Enter your code here",
                            hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.7)),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _errorMessage,
                            errorStyle: const TextStyle(color: AppTheme.errorColor),
                          ),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor
                                )
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _joinParty,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'JOIN CHALLENGE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _partyCodeController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
