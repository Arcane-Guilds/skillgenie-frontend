import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../core/constants/api_constants.dart';
import 'challenges_screen.dart';

class PartyCodeScreen extends StatefulWidget {
  const PartyCodeScreen({Key? key}) : super(key: key);

  @override
  _PartyCodeScreenState createState() => _PartyCodeScreenState();
}

class _PartyCodeScreenState extends State<PartyCodeScreen> {
  final TextEditingController _partyCodeController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    socket = IO.io(
        '${ApiConstants.baseUrl}/socket.io',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build());

    socket!.connect();

    socket!.onConnect((_) {
      print('Connected to WebSocket');
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
      print("Player joined: ${data['users']}");
      _showSnackbar("Player joined: ${data['users']}");
    });

    socket!.on('gameStarted', (data) {
      print("Game started with party code: ${data['partyId']}");
      _navigateToChallenge(data['partyId']);
    });

    socket!.onDisconnect((_) => print('Disconnected from WebSocket'));
    socket!.onError((err) => print('Socket error: $err'));
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _generatePartyCode() {
    socket!.emit('generateParty');
  }

  void _joinParty() {
    if (_joinCodeController.text.isEmpty) {
      _showSnackbar('Please enter a party code');
      return;
    }
    socket!.emit('joinParty', {'partyId': _joinCodeController.text});
  }

  void _startGame() {
    if (_partyCodeController.text.isEmpty) {
      _showSnackbar('Please generate a party code first');
      return;
    }
    socket!.emit('startGame', {'partyId': _partyCodeController.text});
  }

  void _navigateToChallenge(String partyCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengesScreen(partyCode: partyCode),
      ),
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    _partyCodeController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Code'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create Party Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a Party',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _partyCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Party Code',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.group),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generatePartyCode,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate Code'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _partyCodeController.text));
                            _showSnackbar('Party code copied to clipboard');
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Join Party Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Join a Party',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _joinCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Party Code',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.group_add),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _joinParty,
                      icon: const Icon(Icons.login),
                      label: const Text('Join Party'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 