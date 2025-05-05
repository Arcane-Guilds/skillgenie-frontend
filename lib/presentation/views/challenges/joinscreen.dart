import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'challenges_screen.dart';
import '../../widgets/avatar_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';


class JoinPartyScreen extends StatefulWidget {
  _JoinPartyScreenState createState() => _JoinPartyScreenState();
}

  @override
  _JoinPartyScreenState createState() => _JoinPartyScreenState();


class _JoinPartyScreenState extends State<JoinPartyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GenieAvatar(state: AvatarState.idle, size: 200),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Enter your party code!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _partyCodeController,
                        decoration: InputDecoration(
                          labelText: "Party Code",
                          labelStyle: const TextStyle(color: Colors.deepPurple),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          _joinParty();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                          minimumSize: const Size(140, 50),
                        ),
                        child: const Text(
                          'JOIN PARTY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
    );

  }
}
