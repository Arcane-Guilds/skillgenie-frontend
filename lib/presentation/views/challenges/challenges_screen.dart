import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../../../core/constants/api_constants.dart';

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
    final String apiUrl = '${ApiConstants.baseUrl}/challenges/get-by-party/${widget.partyCode}';

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
        _resultMessage = '⚠️ Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  // 🟢 Method to submit the solution
  Future<void> _submitSolution() async {
    final String apiUrl = '${ApiConstants.baseUrl}/challenges/submit-solution';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partyCode': widget.partyCode,
          'solution': _solutionController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultMessage = data['isCorrect'] 
              ? '✅ Bravo! Votre solution est correcte.' 
              : '❌ Désolé, votre solution est incorrecte.';
        });
      } else {
        setState(() {
          _resultMessage = '⚠️ Erreur lors de la soumission de la solution.';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '⚠️ Erreur de connexion: $e';
      });
    }
  }

  // 🟢 Start the countdown timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _isTimeUp = true;
          _timer.cancel();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchChallengeData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _solutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge'),
        actions: [
          // Timer display in the app bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _remainingTime < 10 ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '⏱️ $_remainingTime s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isTimeUp
              ? _buildTimeUpScreen()
              : _buildChallengeScreen(),
    );
  }

  // 🟢 Widget for when time is up
  Widget _buildTimeUpScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_off, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Temps écoulé!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vous n\'avez pas soumis votre solution à temps.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  // 🟢 Widget for the challenge screen
  Widget _buildChallengeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge title
          Text(
            challengeTitle ?? 'Challenge',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          // Challenge metadata (difficulty and language)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(challengeDifficulty),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  challengeDifficulty ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  challengeLanguage ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Challenge description
          const Text(
            'Description:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              challengeDescription ?? 'No description available',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
          
          // Solution input
          const Text(
            'Votre solution:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: _solutionController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Entrez votre code ici...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitSolution,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Soumettre la solution',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          // Result message
          if (_resultMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _resultMessage.contains('✅') ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _resultMessage,
                style: TextStyle(
                  color: _resultMessage.contains('✅') ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🟢 Helper method to get color based on difficulty
  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 