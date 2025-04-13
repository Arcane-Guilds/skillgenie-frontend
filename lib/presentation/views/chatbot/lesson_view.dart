import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/lesson_view_model.dart';


class LessonView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LessonViewModel(),
      child: Scaffold(
        appBar: AppBar(title: Text("Générateur de vidéo de leçon")),
        body: Consumer<LessonViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: viewModel.pickAndExtractText,
                    child: Text("Sélectionner PDF et extraire texte"),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(viewModel.lessonContent.isNotEmpty 
                          ? viewModel.lessonContent 
                          : "Aucun texte extrait."),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (viewModel.isProcessing)
                    Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: viewModel.lessonContent.isNotEmpty
                              ? () async {
                                  await viewModel.generateVideoFromImages();
                                }
                              : null,
                          child: Text("Générer Vidéo"),
                        ),
                        // ElevatedButton(
                        //   onPressed: viewModel.lessonContent.isNotEmpty
                        //       ? () async {
                        //           await viewModel.addAudioToVideo();
                        //         }
                        //       : null,
                        //   child: Text("Ajouter Audio"),
                        // ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
