import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:lottie/lottie.dart';
import 'package:skillGenie/core/constants/api_constants.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChallengesScreen extends StatefulWidget {
  final String partyCode;
  final String challengeId;

  const ChallengesScreen({
    super.key,
    required this.partyCode,
    required this.challengeId,
  });

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
  Map<String, dynamic>? challengeSolutions;
  String _resultMessage = '';
  bool _isTimeUp = false;
  int _remainingTime = 60;
  bool _hasSubmitted = false;
  bool _chance = true;
  int _nb = 0; // Tracks number of correct answers
  int _coinBalance = 0;
  final TextEditingController _solutionController = TextEditingController();
  final CountDownController _timerController = CountDownController();
  List<String> partyUsers = [];
  Timer? _pollTimer; // Timer for polling party users
  Timer? _localTimer; // Local timer for countdown
  bool _isWaitingForSecondUser = true; // Track waiting state
  int? _startTime; // Server-provided start time (Unix timestamp in seconds)
  bool _isTimerRunning = false; // Track timer running state

  late AnimationController _animationController;
  late Animation<Offset> _genieOffset;
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _fetchChallengeData();
    _fetchCoinBalance();
    _fetchPartyUsers();
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

    // Start polling for party users every 500ms for faster detection
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _fetchPartyUsers();
    });
  }

  @override
  void dispose() {
    _solutionController.dispose();
    _pollTimer?.cancel();
    _localTimer?.cancel();
    _animationController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _fetchChallengeData() async {
    setState(() {
      isLoading = true;
      _resultMessage = '';
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id;
    if (userId == null) {
      setState(() {
        _resultMessage = '⚠️ Utilisateur non authentifié';
        isLoading = false;
      });
      return;
    }

    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/get-by-party/${widget.partyCode}?challengeId=${widget.challengeId}&userId=$userId';

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Délai dépassé : Échec de la récupération du défi');
        },
      );

      print(
          'Challenge fetch response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          final challengeData =
              data[0] as Map<String, dynamic>; // Access the first element
          setState(() {
            challengeTitle = challengeData['title'] ?? 'Sans titre';
            challengeDescription =
                challengeData['description'] ?? 'Aucune description';
            challengeDifficulty = challengeData['difficulty'] ?? 'Inconnu';
            challengeLanguage = challengeData['languages']?.isNotEmpty == true
                ? challengeData['languages'][0]
                : 'Inconnu';
            challengeSolutions = challengeData['solutions'] ?? {};
            isLoading = false;
          });
        } else {
          setState(() {
            _resultMessage = '⚠️ Aucun défi trouvé';
            isLoading = false;
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _resultMessage =
              '⚠️ ${errorData['message'] ?? 'Erreur lors de la récupération des détails'}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
        isLoading = false;
      });
      print('Error fetching challenge: $e');
    }
  }

  Future<void> _fetchCoinBalance() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id;

    if (userId == null) {
      setState(() {
        _resultMessage = '⚠️ Utilisateur non authentifié';
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
          _resultMessage =
              '⚠️ Erreur lors de la récupération du solde de pièces';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
      });
      print('Error fetching coin balance: $e');
    }
  }

  Future<void> _fetchPartyUsers() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/party-code/users/${widget.partyCode}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          partyUsers = List<String>.from(data['users']);
          final isComplete = data['isComplete'] ?? false;
          _startTime = data['startTime'];

          if (isComplete && !_hasSubmitted) {
            // Challenge is complete (another user won)
            _chance = false;
            _remainingTime = 0;
            _isTimeUp = true;
            _isTimerRunning = false;
            _localTimer?.cancel();
            _timerController.pause();
            _pollTimer?.cancel();
            _showChallengeOverAlert();
          } else if (partyUsers.length >= 2 && _isWaitingForSecondUser) {
            // Second user joined, start the timer
            _isWaitingForSecondUser = false;
            _startLocalTimer();
            _isTimerRunning = true;
            print(
                'Second user joined, starting timer with startTime: $_startTime');
          }
        });
      } else {
        setState(() {
          _resultMessage =
              '⚠️ Erreur lors de la récupération des utilisateurs de la fête';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
      });
      print('Error fetching party users: $e');
    }
  }

  void _startLocalTimer() {
    if (_localTimer != null || _isTimerRunning)
      return; // Prevent multiple timers
    _remainingTime = 60; // Start from 60 seconds
    _timerController.restart(duration: _remainingTime);
    _timerController.start();

    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_hasSubmitted || _isTimeUp) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          _timerController.restart(duration: _remainingTime);
          if (!_isTimerRunning) {
            _timerController.start();
            _isTimerRunning = true;
          }
        } else {
          _remainingTime = 0;
          _isTimeUp = true;
          _isTimerRunning = false;
          _timerController.pause();
          _localTimer?.cancel();
          _pollTimer?.cancel();
          if (!_hasSubmitted) {
            Alert(
              context: context,
              title: '⏰ Temps écoulé !',
              desc: 'Vous ne pouvez plus soumettre de réponse.',
              type: AlertType.warning,
              buttons: [
                DialogButton(
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close alert
                    Navigator.pop(context); // Exit challenge screen
                  },
                ),
              ],
            ).show();
          }
        }
      });
    });
  }

  Future<void> _checkAnswer() async {
    final userAnswer = _solutionController.text.trim();

    if (userAnswer.isEmpty) {
      setState(() {
        _resultMessage = "Veuillez entrer une solution.";
      });
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser?.id;
    if (userId == null) {
      setState(() {
        _resultMessage = '⚠️ Utilisateur non authentifié';
      });
      return;
    }

    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/check-answers/${widget.partyCode}';
    final String apiUrlstatus =
        '${ApiConstants.baseUrl}/challenges/check-status/${widget.partyCode}';

    final Map<String, dynamic> requestBody = {
      "language": challengeLanguage ?? "Python",
      "answer": userAnswer,
      "userId": userId,
    };

    try {
      // Check party status first
      final statusResponse = await http.get(
        Uri.parse(apiUrlstatus),
        headers: {'Content-Type': 'application/json'},
      );

      print(
          'Check status response: status=${statusResponse.statusCode}, body=${statusResponse.body}');

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        if (statusData['status'] == 'completed') {
          setState(() {
            _hasSubmitted = true;
            _remainingTime = 0;
            _isTimeUp = true;
            _isTimerRunning = false;
            _timerController.pause();
            _localTimer?.cancel();
            _pollTimer?.cancel();
            _resultMessage = '⏰ Défi terminé !';
            _showChallengeOverAlert();
            print('Challenge over for User Y');
          });
          return;
        }
      } else {
        final errorData = jsonDecode(statusResponse.body);
        setState(() {
          _resultMessage =
              '⚠️ ${errorData['message'] ?? 'Erreur lors de la vérification du statut. Veuillez réessayer.'}';
        });
        return;
      }

      // Proceed with answer submission if status is active
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print(
          'Check answer response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['message'] == 'Challenge already completed') {
            // Challenge already won by User X, end for User Y
            _hasSubmitted = true;
            _remainingTime = 0;
            _isTimeUp = true;
            _isTimerRunning = false;
            _timerController.pause();
            _localTimer?.cancel();
            _pollTimer?.cancel();
            _resultMessage = '⏰ Défi terminé !';
            _showChallengeOverAlert();
            print('Challenge over for User Y');
          } else {
            _resultMessage = data['correct']
                ? '✅ Réponse correcte !'
                : '❌ Mauvaise réponse, essayez encore.';
            if (data['correct']) {
              // First correct answer (User X)
              _hasSubmitted = true;
              _remainingTime = 0;
              _isTimeUp = true;
              _isTimerRunning = false;
              _timerController.pause();
              _localTimer?.cancel();
              _pollTimer?.cancel();
              _showWinAlert();
              _declareWinner(userId);
              _addCoins(userId, 10);
            }
          }
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _resultMessage =
              '⚠️ ${errorData['message'] ?? 'Erreur lors de la vérification. Veuillez réessayer.'}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
      });
      print('Error checking answer: $e');
    }
  }

  Future<void> _declareWinner(String userId) async {
    final String apiUrl =
        '${ApiConstants.baseUrl}/challenges/${widget.partyCode}/declare-winner';

    final Map<String, dynamic> requestBody = {
      "userId": userId,
      "challengeId": widget.challengeId,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print(
          'Declare winner response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        setState(() {
          _resultMessage =
              '⚠️ ${errorData['message'] ?? 'Erreur lors de la déclaration du gagnant.'}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '🚨 Erreur : ${e.toString()}';
      });
      print('Error declaring winner: $e');
    }
  }

  Future<void> _addCoins(String userId, int amount) async {
    final String apiUrl = '${ApiConstants.baseUrl}/user/$userId/coins';

    final Map<String, dynamic> requestBody = {
      "amount": amount,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print(
          'Add coins response: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _coinBalance = data['coins'] ?? _coinBalance + amount;
          _resultMessage = '✅ $amount pièces ajoutées avec succès !';
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _resultMessage =
              '⚠️ ${errorData['message'] ?? 'Erreur lors de l\'ajout des pièces.'}';
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage =
            '🚨 Erreur lors de l\'ajout des pièces : ${e.toString()}';
      });
      print('Error adding coins: $e');
    }
  }

  void _showWinAlert() {
    Alert(
      context: context,
      title: '🎉 Félicitations !',
      desc: 'Vous avez gagné ! 🎉',
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
            'Vous avez gagné 10 pièces ! 🎊',
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
          onPressed: () {
            Navigator.pop(context); // Close alert
            Navigator.pop(context); // Exit challenge screen
          },
        ),
      ],
    ).show();
  }

  void _showChallengeOverAlert() {
    Alert(
      context: context,
      title: '⏰ Défi terminé !',
      desc: 'Un autre joueur a remporté le défi.',
      type: AlertType.warning,
      buttons: [
        DialogButton(
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            Navigator.pop(context); // Close alert
            Navigator.pop(context); // Exit challenge screen
          },
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
    await flutterTts.setSpeechRate(0.5);
    var result = await flutterTts.speak(textToSpeak);

    print("🔊 Speak result: $result");
  }

  void _sharePartyCode() {
    final String textToShare =
        'Rejoignez mon défi avec le code de la fête : ${widget.partyCode}';
    Clipboard.setData(ClipboardData(text: textToShare)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copié dans le presse-papiers'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("💡 Défi"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePartyCode,
            tooltip: 'Partager le code de la fête',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple))
          : challengeTitle == null
              ? Center(
                  child: Text(_resultMessage.isNotEmpty
                      ? _resultMessage
                      : "❌ Aucun défi disponible."))
              : _isWaitingForSecondUser && partyUsers.length < 2
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                              color: Colors.deepPurple),
                          const SizedBox(height: 16),
                          const Text(
                            'En attente d\'un autre joueur...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Code de la fête : ${widget.partyCode}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _sharePartyCode,
                            icon: const Icon(Icons.share),
                            label: const Text('Partager le code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    duration: _remainingTime,
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
                                      setState(() {
                                        _isTimeUp = true;
                                        _isTimerRunning = false;
                                        _remainingTime = 0;
                                      });
                                      if (!_hasSubmitted) {
                                        Alert(
                                          context: context,
                                          title: '⏰ Temps écoulé !',
                                          desc:
                                              'Vous ne pouvez plus soumettre de réponse.',
                                          type: AlertType.warning,
                                          buttons: [
                                            DialogButton(
                                              child: const Text(
                                                'OK',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(
                                                    context); // Close alert
                                                Navigator.pop(
                                                    context); // Exit challenge screen
                                              },
                                            ),
                                          ],
                                        ).show();
                                      }
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomPaint(
                                          painter: TrianglePainter(
                                              color: Colors.white),
                                          child: const SizedBox(
                                              width: 20, height: 10),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
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
                                                challengeTitle ?? 'Sans titre',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                challengeDescription ??
                                                    'Aucune description',
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
                                                    avatar: const Icon(
                                                        Icons.star,
                                                        size: 18,
                                                        color: Colors.amber),
                                                    label: Text(
                                                      challengeDifficulty ??
                                                          'Inconnu',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    backgroundColor:
                                                        Colors.amber[100],
                                                  ),
                                                  Chip(
                                                    avatar: const Icon(
                                                        Icons.code,
                                                        size: 18,
                                                        color: Colors.blue),
                                                    label: Text(
                                                      challengeLanguage ??
                                                          'Inconnu',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                    backgroundColor:
                                                        Colors.blue[100],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: _speakChallenge,
                                                icon:
                                                    const Icon(Icons.volume_up),
                                                label: const Text(
                                                    "Lire le défi à voix haute"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
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
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _solutionController,
                                maxLines: 5,
                                enabled: !_isTimeUp &&
                                    !_hasSubmitted, // Disable if time up or submitted
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                              const SizedBox(height: 20),
                              if (challengeSolutions != null) ...[
                                const SizedBox(height: 20),
                              ],
                            ],
                          ),
                        ),
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
