import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
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
                        // Video player widget to display and play the video
                        if (viewModel.generatedVideoPath != null)
                          VideoPlayerWidget(
                            videoPath: viewModel.generatedVideoPath!,
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

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;

  VideoPlayerWidget({required this.videoPath});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {}); // Rebuild the widget when the video is initialized
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: () {
                setState(() {
                  _controller.seekTo(Duration.zero);
                  _controller.pause();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
