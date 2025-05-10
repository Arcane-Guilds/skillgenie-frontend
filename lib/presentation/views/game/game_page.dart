import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/selectable_letter.dart';
import 'package:skillGenie/presentation/views/game/selected_letter.dart';
import 'package:provider/provider.dart';

import '../../../core/services/service_locator.dart';
import '../../viewmodels/game/game_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => serviceLocator<GameViewModel>(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE3F2FD), // Light blue background
        appBar: AppBar(
          backgroundColor: const Color(0xFFE3F2FD), // Light blue app bar
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue[900]), // Dark blue for contrast
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Word Jumble',
            style: TextStyle(
              color: Colors.blue[900], // Dark blue for contrast
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE3F2FD), // Light blue
                const Color(0xFFBBDEFB), // Slightly darker light blue
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Consumer<GameViewModel>(
                builder: (context, viewModel, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Word Hint\n${viewModel.hint}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            viewModel.resetGame();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('New Word'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[900],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const SelectedLetterView(),
              const Spacer(),
              Container(
                width: 400,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<GameViewModel>(
                  builder: (context, viewModel, child) {
                    return Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: List.generate(
                        10,
                        (index) => SelectableLetter(
                          index: index,
                          onTap: () {
                            viewModel.selectWord(index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
