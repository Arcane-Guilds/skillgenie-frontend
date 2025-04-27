import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'challenges_screen.dart';
import '../../widgets/avatar_widget.dart';

class PartyCodeScreen extends StatefulWidget {
  const PartyCodeScreen({super.key});

  @override
  _PartyCodeScreenState createState() => _PartyCodeScreenState();
}

class _PartyCodeScreenState extends State<PartyCodeScreen> {
  final TextEditingController _partyCodeController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  IO.Socket? socket;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('✅ Connected to WebSocket');
    });

    socket!.on('partyGenerated', (data) {
      setState(() {
        _partyCodeController.text = data['partyId'];
      });
    });

    socket!.on('partyError', (data) {
      _showSnackbar(data['message']);
    });

    socket!.on('playerJoined', (data) {
      print("👥 Player joined: ${data['users']}");
    });
  }

  // 🟢 Generate Party Code
  Future<void> _generateParty() async {
    setState(() => isLoading = true);

    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}'
          '/party-code/generate'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _partyCodeController.text = data['code'];
        });
      } else {
        _showSnackbar('❌ Failed to generate party code');
      }
    } catch (e) {
      _showSnackbar('❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🟢 Join Party
  Future<void> _joinParty() async {
    final String code = _joinCodeController.text.trim();
    if (code.isEmpty) {
      _showSnackbar('⚠️ Please enter a valid party code');
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final String? userId = authViewModel.user?.id;

    if (userId == null) {
      _showSnackbar('⚠️ User not authenticated');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/party-code/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'userId': userId}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          _showSnackbar('✅ Joined party successfully');

          // 🔥 Check if the party now has 2 or more users
          _checkAndNavigate(code);
        } else {
          _showSnackbar('❌ Failed to join party');
        }
      } else {
        _showSnackbar('❌ Failed to join party');
      }
    } catch (e) {
      _showSnackbar('❌ Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅ Fetch users in party & navigate if at least 2 users
  Future<void> _checkAndNavigate(String code) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/party-code/users/$code'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> users = data['users'];

        print("👥 Current Party Users: $users");

        if (users.isNotEmpty) {
          _goToChallengeScreen(code);
        }
      } else {
        _showSnackbar('❌ Failed to fetch party users');
      }
    } catch (e) {
      _showSnackbar('❌ Error: $e');
    }
  }

  // ✅ Navigate to ChallengeScreen
  void _goToChallengeScreen(String partyCode) {
    print("🚀 Navigating to ChallengeScreen with partyCode: $partyCode");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengesScreen(partyCode: partyCode),
      ),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _partyCodeController.text));
    _showSnackbar('📋 Code copied to clipboard');
  }

  void _pasteCode() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      setState(() {
        _joinCodeController.text = data.text ?? '';
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                GenieAvatar(
                  state: AvatarState.idle,
                  size: 120,
                  message: "Invite your friends by sharing or joining a party code!",
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppTheme.surfaceColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Invite by Party Code',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _partyCodeController,
                          readOnly: true,
                          style: TextStyle(color: AppTheme.textPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Generated Party Code",
                            labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _copyCode,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isLoading ? null : _generateParty,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh),
                                label: const Text('Generate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _joinCodeController,
                          style: TextStyle(color: AppTheme.textPrimaryColor),
                          decoration: InputDecoration(
                            labelText: "Enter Party Code",
                            labelStyle: TextStyle(color: AppTheme.textSecondaryColor),
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pasteCode,
                                icon: const Icon(Icons.paste),
                                label: const Text('Paste'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _joinParty,
                                icon: const Icon(Icons.login),
                                label: const Text('Join'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _goToChallengeScreen(_partyCodeController.text),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Go to Challenge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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