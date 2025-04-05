import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class HangmanWords {
  int _wordCounter = 0;
  final List<int> _usedIndices = [];
  final Map<String, String> _wordsWithHints = {
    "variable": "A named storage for data in programming.",
    "function": "A reusable block of code that performs a task.",
    "loop": "A control structure that repeats actions.",
    "class": "A blueprint for creating objects in OOP.",
    "interface": "Defines a contract that classes must follow.",
    "widget": "A UI element in Flutter.",
    "state": "Holds data that can change in a Flutter app.",
    "async": "A keyword for handling asynchronous operations.",
    "package": "A collection of related Dart files and assets.",
    "database": "Stores and retrieves structured data.",
  };

  List<String> _wordList = [];

  HangmanWords() {
    _wordList = _wordsWithHints.keys.toList(); // Extract words from the map
  }

  Future<void> readWords() async {
    String fileText = await rootBundle.loadString('res/hangman_words.txt');
    _wordList = fileText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void resetWords() {
    _wordCounter = 0;
    _usedIndices.clear();
  }

  String getWord() {
    if (_usedIndices.length >= _wordList.length) {
      return ''; // No words left to use
    }

    _wordCounter++;
    int wordIndex;
    Random rand = Random();

    do {
      wordIndex = rand.nextInt(_wordList.length);
    } while (_usedIndices.contains(wordIndex));

    _usedIndices.add(wordIndex);
    return _wordList[wordIndex];
  }

  String getHint(String word) {
    return _wordsWithHints[word] ?? "No hint available.";
  }

  String getWordDescription(String word) {
    // Assuming word descriptions are the same as the hints in your map
    return _wordsWithHints[word] ?? "No description available.";
  }

  String getHiddenWord(int wordLength) {
    return List.filled(wordLength, '_').join();
  }
}
