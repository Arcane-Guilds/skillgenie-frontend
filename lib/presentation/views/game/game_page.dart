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
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Word Jumble',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
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
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "Word Hint\n${viewModel.hint}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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
