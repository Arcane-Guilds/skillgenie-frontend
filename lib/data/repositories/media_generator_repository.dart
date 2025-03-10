import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:logging/logging.dart';

/// Repository for lesson-related operations
class MediaGeneratorRepository {
  final FlutterTts _flutterTts;
  final Logger _logger = Logger('LessonRepository');

  MediaGeneratorRepository({required FlutterTts flutterTts}) : _flutterTts = flutterTts;

  /// Pick a PDF file and extract text
  Future<String> pickAndExtractText() async {
    try {
      _logger.info('Picking PDF file');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        return await extractTextFromPDF(filePath);
      } else {
        _logger.warning('No file selected');
        return "Aucun fichier sélectionné.";
      }
    } catch (e) {
      _logger.severe('Error picking file: $e');
      return "Erreur lors de la sélection du fichier : $e";
    }
  }

  /// Extract text from a PDF file
  Future<String> extractTextFromPDF(String filePath) async {
    try {
      _logger.info('Extracting text from PDF: $filePath');
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception("Le fichier n'existe pas.");
      }

      List<int> bytes = await file.readAsBytes();
      PdfDocument document = PdfDocument(inputBytes: bytes);
      String extractedText = PdfTextExtractor(document).extractText();
      document.dispose(); // Free memory

      if (extractedText.trim().isEmpty) {
        throw Exception("Aucun texte trouvé dans le PDF.");
      }

      return extractedText;
    } catch (e) {
      _logger.severe('Error extracting text from PDF: $e');
      return "Échec de l'extraction du texte. Erreur : $e";
    }
  }

  /// Convert text to TTS audio and save to file
  Future<String> generateAudioFromText(String text) async {
    try {
      _logger.info('Generating audio from text');
      final directory = await getApplicationDocumentsDirectory();
      final audioPath = "${directory.path}/speech.mp3";

      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.synthesizeToFile(text, audioPath);

      return audioPath;
    } catch (e) {
      _logger.severe('Error generating audio from text: $e');
      throw Exception("Error generating audio: $e");
    }
  }

  /// Generate an image from text
  Future<String> generateImageFromText(String text, int index) async {
    try {
      _logger.info('Generating image from text for index: $index');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: Colors.black, fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: 800);
      textPainter.paint(canvas, Offset(50, 50));

      final picture = recorder.endRecording();
      final img = await picture.toImage(900, 600);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = "${directory.path}/page_$index.png";
      final file = File(imagePath);
      await file.writeAsBytes(buffer);

      return imagePath;
    } catch (e) {
      _logger.severe('Error generating image from text: $e');
      throw Exception("Error generating image: $e");
    }
  }

  /// Generate all images from text
  Future<List<String>> generateImagesFromText(String text) async {
    try {
      _logger.info('Generating images from text');
      List<String> imagePaths = [];
      List<String> textPages = text.split("\n\n");

      for (int i = 0; i < textPages.length; i++) {
        String path = await generateImageFromText(textPages[i], i);
        imagePaths.add(path);
      }

      return imagePaths;
    } catch (e) {
      _logger.severe('Error generating images from text: $e');
      throw Exception("Error generating images: $e");
    }
  }

  /// Generate a video from images
  Future<String> generateVideoFromImages(List<String> imagePaths) async {
    try {
      _logger.info('Generating video from images');
      final directory = await getApplicationDocumentsDirectory();
      String imageListFile = "${directory.path}/images.txt";
      File(imageListFile).writeAsStringSync(
          imagePaths.map((path) => "file '$path'").join("\n"));

      final String videoPath = "${directory.path}/output_video.mp4";

      await FFmpegKit.execute(
          "-f concat -safe 0 -i $imageListFile -vf fps=1 -y $videoPath");

      return videoPath;
    } catch (e) {
      _logger.severe('Error generating video from images: $e');
      throw Exception("Error generating video: $e");
    }
  }

  /// Add TTS audio to video
  Future<String> addAudioToVideo(String audioPath, String videoPath) async {
    try {
      _logger.info('Adding audio to video');
      final directory = await getApplicationDocumentsDirectory();
      String finalVideoPath = "${directory.path}/final_video.mp4";

      await FFmpegKit.execute(
          '-i $videoPath -i $audioPath -c:v copy -c:a aac -strict experimental -shortest -y $finalVideoPath');

      return finalVideoPath;
    } catch (e) {
      _logger.severe('Error adding audio to video: $e');
      throw Exception("Error adding audio to video: $e");
    }
  }
} 