import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
        'http://localhost:3000/socket.io',
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
    });
  }

  void _generateParty() {
    socket!.emit('generateParty');
  }

  void _joinParty() {
    String code = _joinCodeController.text.trim();
    if (code.isEmpty) {
      _showSnackbar('Please enter a valid party code');
      return;
    }

    socket!.emit('joinParty', {'partyId': code});
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _partyCodeController.text));
    _showSnackbar('Code copied to clipboard');
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
                  const Text('Invite by Party Code',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _partyCodeController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: "Generated Party Code",
                        labelStyle: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: _copyCode, child: const Text('Copy')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: _generateParty,
                          child: const Text('Generate')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _joinCodeController,
                    decoration: const InputDecoration(
                        labelText: "Enter Party Code",
                        labelStyle: TextStyle(color: Colors.white)),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
