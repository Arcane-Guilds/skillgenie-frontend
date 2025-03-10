import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/media_generator_viewmodel.dart';
import '../../../core/services/service_locator.dart';

class MediaGeneratorView extends StatelessWidget {
  const MediaGeneratorView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => serviceLocator<MediaGeneratorViewModel>(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Générateur de vidéo de leçon")),
        body: Consumer<MediaGeneratorViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: viewModel.pickAndExtractText,
                    child: const Text("Sélectionner PDF et extraire texte"),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(viewModel.mediaGeneratorContent),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (viewModel.isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: viewModel.generateVideoFromImages,
                          child: const Text("Générer Vidéo"),
                        ),
                        ElevatedButton(
                          onPressed: viewModel.addAudioToVideo,
                          child: const Text("Ajouter Audio"),
                        ),
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