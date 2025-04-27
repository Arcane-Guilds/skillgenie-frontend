import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../widgets/avatar_widget.dart';
import 'challenges_screen.dart';

class GenerateCodeScreen extends StatefulWidget {
  const GenerateCodeScreen({super.key});

  @override
  _GenerateCodeScreenState createState() => _GenerateCodeScreenState();
}

class _GenerateCodeScreenState extends State<GenerateCodeScreen> {
  final TextEditingController generatedCodeController = TextEditingController();
  bool isLoading = false;

  Future<void> generatePartyCode() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/party-code/generate'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          generatedCodeController.text = data['code'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate code from API')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: generatedCodeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GenieAvatar(
                  state: AvatarState.idle,
                  size: 150,
                  message: "Generate your party code!",
                ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
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
                                onPressed: isLoading ? null : generatePartyCode,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh),
                                label: const Text('GENERATE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                                  minimumSize: const Size(140, 50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: generatedCodeController.text.isEmpty
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChallengesScreen(
                                              partyCode: generatedCodeController.text,
                                            ),
                                          ),
                                        ),
                                icon: const Icon(Icons.login),
                                label: const Text('JOIN'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
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
