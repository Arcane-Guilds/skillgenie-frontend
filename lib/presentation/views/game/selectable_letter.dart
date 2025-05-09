import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game/game_viewmodel.dart';
import '../../../core/constants/game_constants.dart';

class SelectableLetter extends StatelessWidget {
  final int index;
  final VoidCallback onTap;
  
  const SelectableLetter({
    required this.index, 
    required this.onTap, 
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: curvedBox.copyWith(
          color: Colors.blue[100],
        ),
        alignment: Alignment.center,
        width: 50,
        height: 50,
        margin: const EdgeInsets.all(10),
        child: _SelectableLetterContent(index: index),
      ),
    );
  }
}

class _SelectableLetterContent extends StatelessWidget {
  final int index;
  
  const _SelectableLetterContent({
    required this.index
  });

  bool _isActive(int index, List<int> selectedText) {
    return !selectedText.contains(index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedScale(
          scale: _isActive(index, viewModel.selectedText) ? 1 : 0,
          duration: gameAnimationDuration,
          curve: gameAnimationCurve,
          child: Letter(text: viewModel.text[index]),
        );
      },
    );
  }
}

class Letter extends StatelessWidget {
  final String text;
  
  const Letter({
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      alignment: Alignment.center,
      decoration: curvedBox.copyWith(
        color: Colors.white,
        boxShadow: const <BoxShadow>[gameBoxShadow],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          color: Colors.blue[900],
          fontFamily: "Roboto",
        ),
      ),
    );
  }
}
