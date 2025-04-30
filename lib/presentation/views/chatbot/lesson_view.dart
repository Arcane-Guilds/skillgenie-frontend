import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/lesson_view_model.dart';

class LessonView extends StatelessWidget {
  const LessonView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LessonViewModel(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            "Générateur de Vidéo",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.lightBlue,
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        body: Consumer<LessonViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildButton(
                    text: "Sélectionner PDF et extraire texte",
                    icon: Icons.picture_as_pdf,
                    onPressed: viewModel.pickAndExtractText,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        key: ValueKey(viewModel.lessonContent),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            viewModel.lessonContent.isNotEmpty
                                ? viewModel.lessonContent
                                : "Aucun texte extrait.",
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (viewModel.isProcessing)
                    _buildProcessingIndicator()
                  else
                    Column(
                      children: [
                        _buildButton(
                          text: "Générer Vidéo",
                          icon: Icons.video_call,
                          onPressed: viewModel.lessonContent.isNotEmpty
                              ? () async {
                                  await viewModel.generateVideoFromImages();
                                }
                              : null,
                        ),
                        const SizedBox(height: 20),
                        if (viewModel.generatedVideoPath != null)
                          VideoPlayerCard(
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

  Widget _buildButton({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 10),
          Text(
            "Traitement en cours, veuillez patienter...",
            style: GoogleFonts.roboto(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerCard extends StatefulWidget {
  final String videoPath;

  const VideoPlayerCard({super.key, required this.videoPath});

  @override
  _VideoPlayerCardState createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<VideoPlayerCard> {
  late VideoPlayerController _controller;
  final bool _isMuted = false;
  late ValueNotifier<Duration> _videoPositionNotifier;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.addListener(_onVideoPlayerUpdated);
      });

    // Initialize ValueNotifier to track the position of the video
    _videoPositionNotifier = ValueNotifier<Duration>(_controller.value.position);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoPlayerUpdated);
    _controller.dispose();
    _videoPositionNotifier.dispose();
    super.dispose();
  }

  void _onVideoPlayerUpdated() {
    // Update the position of the video every time it changes
    if (_controller.value.isInitialized && _controller.value.position != _videoPositionNotifier.value) {
      _videoPositionNotifier.value = _controller.value.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayer(_controller),
              ),
            ),
            const SizedBox(height: 10),
            VideoPlayerControls(controller: _controller, isMuted: _isMuted),
            const SizedBox(height: 10),
            _buildVideoProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoProgressBar() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _videoPositionNotifier,
      builder: (context, currentPosition, child) {
        return Slider(
          value: currentPosition.inSeconds.toDouble(),
          min: 0.0,
          max: _controller.value.duration.inSeconds.toDouble(),
          onChanged: (double value) {
            setState(() {
              _controller.seekTo(Duration(seconds: value.toInt()));
            });
          },
          activeColor: Colors.lightBlue,
          inactiveColor: Colors.grey[400],
        );
      },
    );
  }
}

class VideoPlayerControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isMuted;

  const VideoPlayerControls({super.key, required this.controller, required this.isMuted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            controller.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: Colors.lightBlue,
            size: 40,
          ),
          onPressed: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        IconButton(
          icon: const Icon(Icons.stop_circle, color: Colors.lightBlue, size: 40),
          onPressed: () {
            controller.seekTo(Duration.zero);
            controller.pause();
          },
        ),
        IconButton(
          icon: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: isMuted ? Colors.grey : Colors.lightBlue,
            size: 30,
          ),
          onPressed: () {
            controller.setVolume(isMuted ? 1.0 : 0.0);
          },
        ),
      ],
    );
  }
}
