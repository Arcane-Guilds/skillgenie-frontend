import 'package:flutter/material.dart';
import '../../../data/models/game_model.dart';
import '../../../core/constants/game_constants.dart';
import '../../../data/repositories/game_repository.dart';

class GameViewModel extends ChangeNotifier {
  late GameState state;
  final GameRepository _gameRepository;
  
  GameViewModel({required GameRepository gameRepository}) 
      : _gameRepository = gameRepository {
    _initializeGame();
  }

  void _initializeGame() {
    var wordData = _gameRepository.getRandomWord();
    state = GameState(
        correctWord: wordData['word']!, 
        hint: wordData['hint']!);
    state.text = _gameRepository.generateRandomLetters(state.correctWord);
    state.selectedText = List.filled(maxFinalLetters, -1);
    state.lowestIndex = 0;
    notifyListeners();
  }

  String get hint => state.hint;
  List<int> get selectedText => state.selectedText;
  String get text => state.text;
  bool? get won => state.won;
  int get lowestIndex => state.lowestIndex;
  String get correctWord => state.correctWord;

  void selectWord(int index) {
    if (state.lowestIndex < maxFinalLetters &&
        !state.selectedText.contains(index)) {
      state.setSelectedText(state.lowestIndex, index);

      state.lowestIndex = state.selectedText.indexOf(-1);
      if (state.lowestIndex == -1) {
        _updateGameState();
        state.lowestIndex = maxFinalLetters;
      }
      notifyListeners();
    }
  }

  void removeWord(int index) {
    if (state.selectedText[index] != -1) {
      if (index < state.lowestIndex) {
        state.lowestIndex = index;
      }
      state.setSelectedText(index, -1);
      state.won = null;
      notifyListeners();
    }
  }

  void _updateGameState() {
    String guessedWord = "";
    for (int index in state.selectedText) {
      guessedWord += state.text[index];
    }
    state.won = _gameRepository.checkGuessedWord(guessedWord, state.correctWord);
    notifyListeners();
  }
  
  void resetGame() {
    _initializeGame();
    notifyListeners();
  }
} 