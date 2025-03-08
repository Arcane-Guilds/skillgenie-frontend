import 'dart:math';
import 'package:logging/logging.dart';
import '../models/game_model.dart';
import '../../core/constants/game_constants.dart';

/// Repository for game-related operations
class GameRepository {
  final Random _random = Random();
  final Logger _logger = Logger('GameRepository');

  /// Get a random word and hint from the wordlist
  Map<String, String> getRandomWord() {
    _logger.info('Getting random word');
    var item = wordlist[_random.nextInt(wordlist.length)];
    return {
      'word': item['word']!.toUpperCase(),
      'hint': item['hint']!,
    };
  }

  /// Generate random letters for the game
  String generateRandomLetters(String correctWord) {
    _logger.info('Generating random letters for word: $correctWord');
    String word = correctWord;
    
    // Add random letters to the correct word
    for (var i = 0; i < maxSelectableLetters - maxFinalLetters; i++) {
      int randomIndex = _random.nextInt(25) + 1;
      word += alphabet[randomIndex];
    }
    
    return shuffleWord(word);
  }

  /// Shuffle a word using Fisher-Yates Algorithm
  String shuffleWord(String word) {
    _logger.info('Shuffling word');
    String shuffledWord = word;
    for (var i = shuffledWord.length - 1; i > 0; i--) {
      int j = _random.nextInt(i);
      String temp = shuffledWord[j];
      shuffledWord = shuffledWord.replaceRange(j, j + 1, shuffledWord[i]);
      shuffledWord = shuffledWord.replaceRange(i, i + 1, temp);
    }
    return shuffledWord;
  }

  /// Check if the guessed word is correct
  bool checkGuessedWord(String guessedWord, String correctWord) {
    _logger.info('Checking guessed word: $guessedWord against correct word: $correctWord');
    return guessedWord == correctWord;
  }
} 