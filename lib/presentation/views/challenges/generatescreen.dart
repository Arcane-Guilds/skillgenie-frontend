import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../widgets/avatar_widget.dart';
import 'challenges_screen.dart';

import 'package:provider/provider.dart';

import 'package:skillGenie/presentation/viewmodels/auth/auth_viewmodel.dart';

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
    print(
        'GenerateCodeScreen initialized with challengeId: ${widget.challengeId}');
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
    if (isGenerating) {
      print('GeneratePartyCode skipped: already generating');
      return;
    }

    // Validate challengeId
    if (widget.challengeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid challenge ID')),
      );
      return;
    }

    // Get userId from AuthViewModel
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

    print(
        'Generating party code for userId: $userId, challengeId: ${widget.challengeId}');

    try {
      String? partyCode = existingPartyCode;
      if (partyCode == null) {
        // Generate new party code
        final response = await http
            .get(Uri.parse('${ApiConstants.baseUrl}/party-code/generate'))
            .timeout(const Duration(seconds: 5), onTimeout: () {
          throw Exception('Request timed out: Failed to generate party code');
        });

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
          print(
              'Failed to generate code: $errorMessage, status: ${response.statusCode}');
          return;
        }

        final data = jsonDecode(response.body);
        partyCode = data['code'];
        print('Generated party code: $partyCode');
      }

      // Update UI with generated code
      setState(() {
        generatedCodeController.text = partyCode!;
        existingPartyCode = partyCode;
      });

      // Join party
      final payload = {
        'code': partyCode,
        'userId': userId,
        'challengeId': widget.challengeId,
      };
      print('Join party payload: ${jsonEncode(payload)}');

      final partyResponse = await http
          .post(
        Uri.parse('${ApiConstants.baseUrl}/party-code/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw Exception('Request timed out: Failed to join party');
      });

      print(
          'Join party response: status=${partyResponse.statusCode}, body=${partyResponse.body}');

      // Check response body for success
      final responseData = jsonDecode(partyResponse.body);
      if (partyResponse.statusCode == 200 || responseData['success'] == true) {
        setState(() {
          isPartyCreated = true;
        });
        print('Party joined successfully with code: $partyCode');
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
        print(
            'Failed to join party: $errorMessage, status: ${partyResponse.statusCode}');
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
      print('Error in generatePartyCode: $e');
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
                const GenieAvatar(
                  state: AvatarState.idle,
                  size: 150,
                  message: "Generate your party code!",
                ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
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
                                  fillColor:
                                      Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy,
                                  color: Theme.of(context).colorScheme.primary),
                              onPressed: copyToClipboard,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    isGenerating ? null : generatePartyCode,
                                icon: isGenerating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh),
                                label: const Text('GENERATE'),
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isPartyCreated
                                    ? () {
                                        print(
                                            'Navigating to ChallengesScreen with party code: ${generatedCodeController.text}');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChallengesScreen(
                                              partyCode:
                                                  generatedCodeController.text,
                                              challengeId: widget.challengeId,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.login),
                                label: const Text('JOIN'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 32),
                                  minimumSize: const Size(140, 50),
                                ),
                              ),
                            ),
                          ],
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
