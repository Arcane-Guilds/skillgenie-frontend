import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChallengesScreen extends StatelessWidget {
  final String partyCode; // Accept partyCode as a parameter

  const ChallengesScreen({super.key, required this.partyCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Challenge")),
      body: ChallengeDetailPage(
          partyCode: partyCode), // Pass partyCode to child widget
    );
  }
}

class ChallengeDetailPage extends StatefulWidget {
  final String partyCode;

  const ChallengeDetailPage({Key? key, required this.partyCode})
      : super(key: key);

  @override
  _ChallengeDetailPageState createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  final TextEditingController _solutionController = TextEditingController();
  String _resultMessage = ''; // To show if the answer is correct or not

  @override
  void dispose() {
    _solutionController.dispose();
    super.dispose();
  }

  // 🟢 Method to check the user's answer using the API
  Future<void> _checkAnswer() async {
    final userAnswer = _solutionController.text.trim();

    if (userAnswer.isEmpty) {
      setState(() {
        _resultMessage = "Veuillez entrer une solution.";
      });
      return;
    }

    // ✅ Use partyCode in the API request
    final String apiUrl =
        'http://localhost:3000/challenges/check-answers/${widget.partyCode}';

    // Create the request body
    final Map<String, dynamic> requestBody = {
      "language": "Python",
      "answer": userAnswer, // Send raw answer instead of adding markdown
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultMessage = data['correct']
              ? '✅ Réponse correcte !'
              : '❌ Mauvaise réponse, essayez encore.';
        });
      } else {
        setState(() {
          _resultMessage =
              '⚠️ Erreur lors de la vérification. Veuillez réessayer.';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Titre : Calcul de la moyenne',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Écris un programme en Python qui calcule la moyenne de trois nombres entiers saisis par l'utilisateur.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text('Difficulté : Facile',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Langage : Python',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Votre solution en Python :",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _solutionController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Écrivez votre solution ici...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkAnswer,
            child: Text('Soumettre la solution'),
          ),
          SizedBox(height: 20),
          // Display the result message (if any)
          if (_resultMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _resultMessage,
                style: TextStyle(
                  color:
                      _resultMessage.contains('✅') ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
