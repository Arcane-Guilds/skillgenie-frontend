import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/hangman/score_screen.dart';
import 'package:skillGenie/core/utils/score_db.dart' as score_database;
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../core/utils/user_scores.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  LoadingScreenState createState() => LoadingScreenState();
}

class LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    queryScores();
  }

  void queryScores() async {
    final database = score_database.openDB();
    List<Score> queryResult = await score_database.scores(database);
    goToScoreScreen(queryResult);
  }

  void goToScoreScreen(List<Score> queryResult) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ScoreScreen(
            query: queryResult,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SpinKitDoubleBounce(
          color: Colors.white,
          size: 100.0,
        ),
      ),
    );
  }
}
