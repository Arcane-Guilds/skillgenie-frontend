import 'package:flutter/material.dart';
import 'package:skillGenie/presentation/views/game/selectable_letter.dart';
import 'package:skillGenie/presentation/views/game/selected_letter.dart';
import 'package:provider/provider.dart';

import '../../../core/services/service_locator.dart';
import '../../viewmodels/game/game_viewmodel.dart';

class Game extends StatelessWidget {
  const Game({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => serviceLocator<GameViewModel>(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0, 0),
              end: Alignment(0, 1),
              colors: [
                Color.fromRGBO(211, 151, 250, 1),
                Color.fromRGBO(131, 100, 232, 1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Consumer<GameViewModel>(
                builder: (context, viewModel, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
                    child: Text(
                      "Word Hint\n${viewModel.hint}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  );
                },
              ),
              const SelectedLetterView(),
              const Spacer(),
              SizedBox(
                width: 400,
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
