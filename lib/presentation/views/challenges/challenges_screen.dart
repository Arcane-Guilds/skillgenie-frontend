import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:lottie/lottie.dart';
import 'package:skillGenie/core/constants/api_constants.dart';
import 'package:skillGenie/core/constants/cloudinary_constants.dart';

class ChallengesScreen extends StatefulWidget {
  final String partyCode;

  const ChallengesScreen({super.key, required this.partyCode});

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? challengeTitle;
  String? challengeDescription;
  String? challengeDifficulty;
  String? challengeLanguage;
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

  Future<void> _fetchChallengeData() async {
    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/get-by-party/${widget.partyCode}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          challengeTitle = data[0]['title'];
          challengeDescription = data[0]['description'];
          challengeDifficulty = data[0]['difficulty'];
          challengeLanguage = data[0]['languages'][0];
          isLoading = false;
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

  Future<void> _checkAnswer() async {
    final userAnswer = _solutionController.text.trim();

    if (userAnswer.isEmpty) {
      setState(() {
        _resultMessage = "Veuillez entrer une solution.";
      });
      return;
    }

    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/check-answers/${widget.partyCode}';

    final Map<String, dynamic> requestBody = {
      "language": challengeLanguage ?? "Python",
      "answer": userAnswer,
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
          if (data['correct']) {
            _coinBalance += 10;
            _showWinAlert();
          }
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

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isTimeUp = true;
        });
      }
    });
  }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
