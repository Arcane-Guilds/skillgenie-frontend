import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';

/// Represents the state of the word jumble game
class GameState {
  /// The indices of the selected letters in the text
  List<int> selectedText = List.filled(maxFinalLetters, -1);
  
  /// The shuffled text containing the correct word and random letters
  String text = "";
  
  /// The index of the lowest empty slot in selectedText
  int lowestIndex = 0;
  
  /// The word that the player needs to guess
  final String correctWord;
  
  /// A hint for the word
  final String hint;
  
  /// Whether the player has won (true), lost (false), or the game is ongoing (null)
  bool? _won;
  
  /// Creates a new game state with the given correct word and hint
  GameState({required this.correctWord, required this.hint});

  /// Gets whether the player has won
  bool? get won => _won;
  
  /// Sets whether the player has won
  set won(bool? value) {
    _won = value;
  }

  /// Sets the selected text at the given index
  void setSelectedText(int index, int value) {
    selectedText[index] = value;
  }
}
