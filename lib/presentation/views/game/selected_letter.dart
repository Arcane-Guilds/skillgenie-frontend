import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/game_constants.dart';
import '../../viewmodels/game/game_viewmodel.dart';

class SelectedLetterView extends StatefulWidget {
  const SelectedLetterView({super.key});

  @override
  State<SelectedLetterView> createState() => _SelectedLetterViewState();
}

class _SelectedLetterViewState extends State<SelectedLetterView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<Animation<double>> _tweens;

  List<Animation<double>> _getTweens(int tweenNumber) {
    return List.generate(
      tweenNumber,
      (index) {
        double interval = 0.2;
        double begin = interval * index;
        return Tween(
          begin: 0.0,
          end: 90 / 360,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              begin,
              begin + interval,
              curve: gameAnimationCurve,
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1250))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {});
        }
      });

    _tweens = _getTweens(5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetAnimation() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.reset();
    setState(() {});
  }

  bool _isActive(int index, List<int> selectedList) {
    return selectedList[index] != -1;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, viewModel, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
              5,
              (index) => _buildButton(
                    _isActive(index, viewModel.selectedText),
                    index,
                    viewModel,
                  )),
        );
      },
    );
  }

  Widget _buildButton(bool active, int index, GameViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        if (!_controller.isAnimating) {
          viewModel.removeWord(index);
        }
        if (_controller.isCompleted) {
          _controller.reset();
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: curvedBox.copyWith(
          color: Colors.blue[100],
        ),
        child: AnimatedScale(
          duration: gameAnimationDuration,
          curve: gameAnimationCurve,
          scale: active ? 1 : 0,
          onEnd: () {
            if (index == 4 && active) {
              _controller.forward();
              setState(() {});
            }
          },
          child: RotationTransition(
            turns: _tweens[index],
            child: LetterTile(
              index: index,
              started: _controller.isAnimating,
              text: active ? _getLetterText(index, viewModel) : "",
              done: _controller.isCompleted,
              won: viewModel.won ?? false,
              correctWord: viewModel.correctWord,
            ),
          ),
        ),
      ),
    );
  }
  
  String _getLetterText(int index, GameViewModel viewModel) {
    int textIndex = viewModel.selectedText[index];
    return viewModel.text[textIndex];
  }
}

class LetterTile extends StatelessWidget {
  final bool started, done, won;
  final int index;
  final String text;
  final String correctWord;
  static bool _dialogShown = false; // Add static flag to track dialog state
  
  const LetterTile({
    this.started = false,
    this.done = false,
    required this.text,
    this.won = false,
    this.index = 0,
    required this.correctWord,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double begin = index * 0.2;
    double end = begin + 0.2;

    return AnimatedContainer(
      duration: gameAnimationDuration,
      decoration: curvedBox.copyWith(
        color: done ? Colors.white : const Color(0xFFE3F2FD),
        boxShadow: const [gameBoxShadow],
      ),
      onEnd: () {
        if (done && !_dialogShown) { // Only show dialog if not already shown
          _dialogShown = true; // Set flag to true before showing dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF2C1E68),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                title: Text(
                  won ? 'Correct!' : 'Wrong!',
                  style: TextStyle(
                    color: won ? const Color(0xFF00e676) : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                    letterSpacing: 1.5,
                  ),
                ),
                content: Text(
                  'The word was: $correctWord',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      _dialogShown = false; // Reset flag when dialog is closed
                      context.go('/games'); // Navigate to games screen using GoRouter
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1250),
        curve: Interval(begin, end),
        opacity: started || done ? 0 : 1,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: Colors.blue[900],
              fontFamily: "Roboto",
            ),
          ),
        ),
      ),
    );
  }
}
