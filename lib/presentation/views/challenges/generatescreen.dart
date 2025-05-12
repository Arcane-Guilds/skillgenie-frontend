import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import 'challenges_screen.dart';
import '../../../core/utils/share_utils.dart';

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

  void _sharePartyCode() {
    if (generatedCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No code to share')),
      );
      return;
    }
    
    ShareUtils.showShareOptions(
      context,
      generatedCodeController.text,
      'Skill Challenge',
    );
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _animation,
                  child: const GenieAvatar(
                    state: AvatarState.idle,
                    size: 120,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Skill Challenge',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!isPartyCreated) ...[
                          const Text(
                            'Generate a unique code to invite a friend to a skill challenge!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isGenerating ? null : generatePartyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.6),
                              ),
                              child: isGenerating
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text('GENERATE CODE'),
                            ),
                          ),
                        ],
                        if (isPartyCreated) ...[
                          const Text(
                            'Share this code with a friend to start the challenge:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: generatedCodeController,
                            readOnly: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppTheme.primaryColor,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.primaryColor.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.copy),
                                color: AppTheme.primaryColor,
                                onPressed: copyToClipboard,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Waiting for someone to join...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _sharePartyCode,
                                  icon: const Icon(Icons.share),
                                  label: const Text('SHARE CODE'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChallengesScreen(
                                          partyCode:
                                              generatedCodeController.text,
                                          challengeId: widget.challengeId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('START'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
