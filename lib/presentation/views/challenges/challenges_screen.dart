import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:lottie/lottie.dart';
import 'package:skillGenie/core/constants/api_constants.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/core/theme/app_theme.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../widgets/avatar_widget.dart';


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

  late AnimationController _animationController;
  late Animation<Offset> _genieOffset;
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _fetchChallengeData();
    _fetchCoinBalance();
    _startTimer();
    //text to sound
    flutterTts = FlutterTts();

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
    // Stop the TTS when the widget is disposed
    flutterTts.stop();
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

  Future<void> _fetchCoinBalance() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id;

    if (userId == null) {
      setState(() {
        _resultMessage = '⚠️ User not authenticated';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/$userId/coins'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _coinBalance = data['coins'] ?? 0;
        });
      } else {
        setState(() {
          _resultMessage = '⚠️ Error fetching coin balance';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Error: ${e.toString()}';
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

  Future<void> _speakChallenge() async {
    String textToSpeak =
        "${challengeTitle ?? ''}. ${challengeDescription ?? ''}";
    print("🔊 Speech content: $textToSpeak");

    await flutterTts.setLanguage("fr-FR");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5); // Ajoute un débit plus lent
    var result = await flutterTts.speak(textToSpeak);

    print("🔊 Speak result: $result");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("💡 Challenge"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
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
                                  Icon(Icons.monetization_on, color: Colors.amber, size: 32),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_coinBalance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
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
                                fillColor: AppTheme.primaryColor,
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
                                    desc: 'Vous ne pouvez plus soumettre de réponse.',
                                    type: AlertType.warning,
                                  ).show();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Card(
                            color: AppTheme.surfaceColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    challengeTitle ?? '',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    challengeDescription ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Chip(
                                        avatar: const Icon(Icons.star, size: 18, color: Colors.amber),
                                        label: Text(
                                          challengeDifficulty ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        backgroundColor: Colors.amber[100],
                                      ),
                                      Chip(
                                        avatar: const Icon(Icons.code, size: 18, color: Colors.blue),
                                        label: Text(
                                          challengeLanguage ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        backgroundColor: Colors.blue[100],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _speakChallenge,
                                    icon: const Icon(Icons.volume_up),
                                    label: const Text("Lire le challenge à voix haute"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Card(
                            color: AppTheme.surfaceColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "💬 Votre solution :",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.deepPurple,
                                    ),
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
                                    onPressed: _isTimeUp || _hasSubmitted ? null : _checkAnswer,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                    child: const Text(
                                      "Vérifier la réponse",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
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
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: GenieAvatar(
                          state: AvatarState.idle,
                          size: 150,
                          message: "Bonne chance !",
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
