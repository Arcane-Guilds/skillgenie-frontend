import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for Timer

class ChallengesScreen extends StatefulWidget {
  final String partyCode; // Accept partyCode as a parameter

  const ChallengesScreen({super.key, required this.partyCode});

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  bool isLoading = true; // To show loading indicator
  String? challengeTitle;
  String? challengeDescription;
  String? challengeDifficulty;
  String? challengeLanguage;
  String _resultMessage = ''; // To show if the answer is correct or not

  bool _isTimeUp = false; // To check if time is up
  int _remainingTime = 60; // 60 seconds countdown
  late Timer _timer; // Timer to manage countdown

  final TextEditingController _solutionController = TextEditingController();

  // 🟢 Method to fetch the challenge data based on partyCode
  Future<void> _fetchChallengeData() async {
    final String apiUrl =
        'http://localhost:3000/challenges/get-by-party/${widget.partyCode}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          challengeTitle = data['title'];
          challengeDescription = data['description'];
          challengeDifficulty = data['difficulty'];
          challengeLanguage = data['language'];
          isLoading = false; // Stop loading after data is fetched
        });
      } else {
        setState(() {
          _resultMessage = '⚠️ Erreur lors de la récupération des détails.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
        isLoading = false;
      });
    }
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
      "language": challengeLanguage ?? "Python", // Default to Python if null
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

  // 🟢 Start the timer countdown when the page loads
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isTimeUp = true; // Time is up
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchChallengeData(); // Fetch the challenge data when the page loads
    _startTimer(); // Start the timer countdown
  }

  @override
  void dispose() {
    _solutionController.dispose();
    _timer.cancel(); // Cancel timer when leaving the page
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Challenge")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display a loading spinner while fetching data
            if (isLoading)
              const CircularProgressIndicator()
            else if (challengeTitle != null && challengeDescription != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Titre : $challengeTitle',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        challengeDescription!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text('Difficulté : $challengeDifficulty',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Langage : $challengeLanguage',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Display the remaining time countdown
            Text(
              "Temps restant : $_remainingTime secondes",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Votre solution en Python :",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _solutionController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Écrivez votre solution ici...',
                border: OutlineInputBorder(),
              ),
              enabled: !_isTimeUp, // Disable the input field after time is up
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isTimeUp
                  ? null
                  : _checkAnswer, // Disable the button after time is up
              child: const Text('Soumettre la solution'),
            ),
            const SizedBox(height: 20),
            // Display the result message (if any)
            if (_resultMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _resultMessage,
                  style: TextStyle(
                    color: _resultMessage.contains('✅')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
