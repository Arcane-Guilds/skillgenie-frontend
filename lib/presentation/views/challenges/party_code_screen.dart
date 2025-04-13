import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'challenges_screen.dart';

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
      backgroundColor: const Color(0xFF111827),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            color: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Invite by Party Code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _partyCodeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Generated Party Code",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: _copyCode, child: const Text('Copy')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isLoading ? null : _generateParty,
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Generate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _joinCodeController,
                    decoration: const InputDecoration(
                      labelText: "Enter Party Code",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: _pasteCode, child: const Text('Paste')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: _joinParty, child: const Text('Join')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        _goToChallengeScreen(_partyCodeController.text),
                    child: const Text('Go to Challenge'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}