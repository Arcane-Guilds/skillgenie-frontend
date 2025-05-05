import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skillGenie/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
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
    print('GenerateCodeScreen build');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '“Generate your party code!”',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _animation,
              child: Image.asset(
                'assets/images/genie.png',
                height: 300,
                width: 300,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: TextField(
                      controller: generatedCodeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Generated Code",
                        labelStyle: const TextStyle(color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                              color: Colors.deepPurple, width: 2),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.deepPurple),
                    onPressed: copyToClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: isGenerating ? null : generatePartyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    minimumSize: const Size(140, 50),
                  ),
                  child: isGenerating
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'GENERATING...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'GENERATE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isPartyCreated
                      ? () {
                          print(
                              'Navigating to ChallengesScreen with party code: ${generatedCodeController.text}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChallengesScreen(
                                partyCode: generatedCodeController.text,
                                challengeId: widget.challengeId,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 32),
                    minimumSize: const Size(140, 50),
                  ),
                  child: const Text(
                    'JOIN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
