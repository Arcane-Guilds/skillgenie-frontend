import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../core/constants/api_constants.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'challenges_screen.dart';

class GenerateCodeScreen extends StatefulWidget {
  final String challengeId;

  const GenerateCodeScreen({super.key, required this.challengeId});

  @override
  _GenerateCodeScreenState createState() => _GenerateCodeScreenState();
}

class _GenerateCodeScreenState extends State<GenerateCodeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final TextEditingController generatedCodeController = TextEditingController();

  bool isPartyCreated = false;
  bool isGenerating = false;
  String? existingPartyCode;

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
    generatedCodeController.dispose();
    super.dispose();
  }

  Future<void> generatePartyCode() async {
    if (isGenerating) return;

    if (widget.challengeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid challenge ID')),
      );
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      String? partyCode = existingPartyCode;

      if (partyCode == null) {
        final response = await http
            .get(Uri.parse('${ApiConstants.baseUrl}/party-code/generate'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode != 200) {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['message'] ?? 'Failed to generate code';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: generatePartyCode,
              ),
            ),
          );
          return;
        }

        final data = jsonDecode(response.body);
        partyCode = data['code'];
      }

      setState(() {
        generatedCodeController.text = partyCode!;
        existingPartyCode = partyCode;
      });

      final payload = {
        'code': partyCode,
        'userId': userId,
        'challengeId': widget.challengeId,
      };

      final partyResponse = await http
          .post(
        Uri.parse('${ApiConstants.baseUrl}/party-code/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 5));

      final responseData = jsonDecode(partyResponse.body);

      if (partyResponse.statusCode == 200 || responseData['success'] == true) {
        setState(() {
          isPartyCreated = true;
        });
      } else {
        final errorMessage = responseData['message'] ?? 'Failed to join party';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Join failed: $errorMessage'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: generatePartyCode,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: generatePartyCode,
          ),
        ),
      );
    } finally {
      setState(() {
        isGenerating = false;
      });
    }
  }

  void copyToClipboard() {
    if (generatedCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No code to copy')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: generatedCodeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '“Generate your party code!”',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _animation,
                  child: Image.asset(
                    'assets/images/genie.png',
                    height: 250,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: generatedCodeController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: "Generated Code",
                                  labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color:
                                Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: copyToClipboard,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed:
                          isGenerating ? null : generatePartyCode,
                          icon: isGenerating
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.refresh),
                          label: Text(
                            isGenerating ? 'GENERATING...' : 'GENERATE',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 32),
                            minimumSize: const Size(140, 50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isPartyCreated)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChallengesScreen(
                                partyCode: generatedCodeController.text,
                                challengeId: widget.challengeId,
                                ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 32),
                              minimumSize: const Size(140, 50),
                            ),
                            child: const Text(
                              'START CHALLENGE',
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
      ),
    );
  }
}
