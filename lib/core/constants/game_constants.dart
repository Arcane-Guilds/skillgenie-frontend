import 'package:flutter/material.dart';

const String alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const int maxFinalLetters = 5;
const int maxSelectableLetters = 10;

const wordlist = [
  { "word": "array", "hint": "A data structure that stores multiple values in a single variable" },
  { "word": "debug", "hint": "The process of finding and fixing errors in code" },
  { "word": "fetch", "hint": "A method used to request data from an API" },
  { "word": "loop", "hint": "A programming construct that repeats a block of code" },
  { "word": "token", "hint": "A piece of data used for authentication or parsing code" },
  { "word": "async", "hint": "A keyword in JavaScript used for handling asynchronous operations" },
  { "word": "scope", "hint": "Determines the visibility and lifetime of variables in a program" },
  { "word": "stack", "hint": "A data structure that follows the Last In, First Out (LIFO) principle" },
  { "word": "tuple", "hint": "An immutable, ordered collection of elements in Python" },
  { "word": "merge", "hint": "A process of combining multiple data sets or branches in coding" }
];

const Duration gameAnimationDuration = Duration(milliseconds: 300);
const Curve gameAnimationCurve = Curves.easeInQuart;
const Curve gameShakeAnimationCurve = SawTooth(4);

const BoxShadow gameBoxShadow = BoxShadow(
  color: Colors.black12,
  blurRadius: 10,
);

BoxDecoration curvedBox = BoxDecoration(borderRadius: BorderRadius.circular(8));
const backgroundBoxColor = Color.fromRGBO(131, 100, 232, .4);
const winBackgroundGradient = LinearGradient(
  colors: [
    Color.fromRGBO(130, 244, 177, 1),
    Color.fromRGBO(48, 198, 124, 1),
  ],
  end: Alignment(0, 1),
);
const lossBackgroundGradient = LinearGradient(
  colors: [
    Color.fromRGBO(255, 184, 142, 1),
    Color.fromRGBO(234, 87, 83, 1),
  ],
  end: Alignment(0, 1),
); 