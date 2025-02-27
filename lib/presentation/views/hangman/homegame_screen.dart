import 'package:flutter/material.dart';
import 'package:frontend/core/utils/hangman_words.dart';


import '../../../core/widgets/action_button.dart';
import 'game_screen.dart';
import 'loading_screen.dart';

class HomeGameScreen extends StatefulWidget {
  final HangmanWords hangmanWords = HangmanWords();

  HomeGameScreen({super.key});

  @override
  HomeGameScreenState createState() => HomeGameScreenState();
}

class HomeGameScreenState extends State<HomeGameScreen> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    widget.hangmanWords.readWords();
    return Scaffold(
      body: SafeArea(
          child: Column(
            children: <Widget>[
              Center(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8.0, 1.0, 8.0, 8.0),
                  child: const Text(
                    'HANGMAN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 58.0,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3.0),
                  ),
                ),
              ),
              Center(
                child: Image.asset(
                  'assets/images/gallow.png',
                  height: height * 0.49,
                ),
              ),
              const SizedBox(
                height: 15.0,
              ),
              Center(
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        height: 64,
                        child: ActionButton(
                          buttonTitle: 'Start',
                          onPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(
                                  hangmanObject: widget.hangmanWords,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 18.0,
                      ),
                      SizedBox(
                        height: 64,
                        child: ActionButton(
                          buttonTitle: 'High Scores',
                          onPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoadingScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
