import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
<<<<<<< Updated upstream

import '../../../core/constants/api_constants.dart'; // Import for Timer

class ChallengesScreen extends StatefulWidget {
  final String partyCode; // Accept partyCode as a parameter
=======
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:lottie/lottie.dart';
import 'package:skillGenie/core/constants/api_constants.dart';
import 'package:skillGenie/core/constants/cloudinary_constants.dart';

class ChallengesScreen extends StatefulWidget {
  final String partyCode;
>>>>>>> Stashed changes

  const ChallengesScreen({super.key, required this.partyCode});

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

<<<<<<< Updated upstream
class _ChallengesScreenState extends State<ChallengesScreen> {
  bool isLoading = true; // To show loading indicator
=======
class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
>>>>>>> Stashed changes
  String? challengeTitle;
  String? challengeDescription;
  String? challengeDifficulty;
  String? challengeLanguage;
<<<<<<< Updated upstream
  String _resultMessage = ''; // To show if the answer is correct or not

  bool _isTimeUp = false; // To check if time is up
  int _remainingTime = 60; // 60 seconds countdown
  late Timer _timer; // Timer to manage countdown

  final TextEditingController _solutionController = TextEditingController();

  // 🟢 Method to fetch the challenge data based on partyCode
=======
  String _resultMessage = '';
  bool _isTimeUp = false;
  int _remainingTime = 60;
  late Timer _timer;
  bool _hasSubmitted = false;
  int _coinBalance = 0;
  final TextEditingController _solutionController = TextEditingController();
  final CountDownController _timerController = CountDownController();
  bool _coinAnimationTriggered = false;

  late AnimationController _animationController;
  late Animation<Offset> _genieOffset;

  @override
  void initState() {
    super.initState();
    _fetchChallengeData();
    _startTimer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _genieOffset = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _solutionController.dispose();
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

>>>>>>> Stashed changes
  Future<void> _fetchChallengeData() async {
    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/get-by-party/${widget.partyCode}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
<<<<<<< Updated upstream
          challengeTitle = data[0]['title']; // Assuming the first challenge
          challengeDescription = data[0]['description'];
          challengeDifficulty = data[0]['difficulty'];
          challengeLanguage =
          data[0]['languages'][0]; // Taking the first language
          isLoading = false; // Stop loading after data is fetched
=======
          challengeTitle = data[0]['title'];
          challengeDescription = data[0]['description'];
          challengeDifficulty = data[0]['difficulty'];
          challengeLanguage = data[0]['languages'][0];
          isLoading = false;
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
  // 🟢 Method to check the user's answer using the API
=======
>>>>>>> Stashed changes
  Future<void> _checkAnswer() async {
    final userAnswer = _solutionController.text.trim();

    if (userAnswer.isEmpty) {
      setState(() {
        _resultMessage = "Veuillez entrer une solution.";
      });
      return;
    }

<<<<<<< Updated upstream
    // ✅ Use partyCode in the API request
    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/check-answers/${widget.partyCode}';

    // Create the request body
    final Map<String, dynamic> requestBody = {
      "language": challengeLanguage ?? "Python", // Default to Python if null
      "answer": userAnswer, // Send raw answer instead of adding markdown
=======
    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/check-answers/${widget.partyCode}';

    final Map<String, dynamic> requestBody = {
      "language": challengeLanguage ?? "Python",
      "answer": userAnswer,
>>>>>>> Stashed changes
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultMessage = data['correct']
              ? '✅ Réponse correcte !'
              : '❌ Mauvaise réponse, essayez encore.';
<<<<<<< Updated upstream
=======
          if (data['correct']) {
            _coinBalance += 10;
            _showWinAlert();
          }
>>>>>>> Stashed changes
        });
      } else {
        setState(() {
          _resultMessage =
<<<<<<< Updated upstream
          '⚠️ Erreur lors de la vérification. Veuillez réessayer.';
=======
              '⚠️ Erreur lors de la vérification. Veuillez réessayer.';
>>>>>>> Stashed changes
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
      });
    }
  }

<<<<<<< Updated upstream
  // 🟢 Start the timer countdown when the page loads
=======
>>>>>>> Stashed changes
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
        setState(() {
<<<<<<< Updated upstream
          _isTimeUp = true; // Time is up
=======
          _isTimeUp = true;
>>>>>>> Stashed changes
        });
      }
    });
  }

<<<<<<< Updated upstream
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
=======
  void _showWinAlert() {
    Alert(
      context: context,
      title: '🎉 Félicitations !',
      desc: 'Vous avez gagné! 🎉',
      content: Column(
        children: [
          Lottie.asset(
            'assets/coin_animation.json',
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          Text(
            'Vous avez gagné 10 coins! 🎊',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      buttons: [
        DialogButton(
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ).show();
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Titre : $challengeTitle',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        challengeDescription!,
                        textAlign: TextAlign.justify,
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
=======
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("💡 Challenge"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : challengeTitle == null
              ? const Center(child: Text("❌ Aucun challenge disponible."))
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/images/coin.jpeg',
                                    width: 40,
                                    height: 40,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_coinBalance',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              CircularCountDownTimer(
                                duration: 60,
                                controller: _timerController,
                                width: 70,
                                height: 70,
                                ringColor: Colors.grey[300]!,
                                fillColor: Colors.deepPurple,
                                backgroundColor: Colors.white,
                                strokeWidth: 8.0,
                                textStyle: const TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                isReverse: true,
                                onComplete: () {
                                  setState(() => _isTimeUp = true);
                                  Alert(
                                    context: context,
                                    title: '⏰ Temps écoulé !',
                                    desc:
                                        'Vous ne pouvez plus soumettre de réponse.',
                                    type: AlertType.warning,
                                  ).show();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomPaint(
                                      painter:
                                          TrianglePainter(color: Colors.white),
                                      child:
                                          const SizedBox(width: 20, height: 10),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            challengeTitle ?? '',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            challengeDescription ?? '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              height: 1.4,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 8,
                                            children: [
                                              Chip(
                                                avatar: const Icon(Icons.star,
                                                    size: 18,
                                                    color: Colors.amber),
                                                label: Text(
                                                  challengeDifficulty ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.amber[100],
                                              ),
                                              Chip(
                                                avatar: const Icon(Icons.code,
                                                    size: 18,
                                                    color: Colors.blue),
                                                label: Text(
                                                  challengeLanguage ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.blue[100],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "💬 Votre solution :",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _solutionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Entrez votre réponse ici...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                            onPressed: _isTimeUp || _hasSubmitted
                                ? null
                                : _checkAnswer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: const Text(
                              "Vérifier la réponse",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          if (_resultMessage.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              _resultMessage,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _resultMessage.startsWith('✅')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Genie positioned at the bottom of the speech bubble
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SlideTransition(
                          position: _genieOffset,
                          child: Image.asset(
                            'assets/images/genie.png',
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
>>>>>>> Stashed changes
