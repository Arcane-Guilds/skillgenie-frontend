import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import '../../data/repositories/lesson_repository.dart';

class LessonViewModel extends ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
  final LessonRepository _lessonRepository;
  String lessonContent = "";
  bool isProcessing = false;

  LessonViewModel({required LessonRepository lessonRepository}) 
      : _lessonRepository = lessonRepository;

  /// ✅ Sélectionner un fichier PDF et extraire le texte
  Future<void> pickAndExtractText() async {
    try {
      String extractedText = await _lessonRepository.pickAndExtractText();
      lessonContent = extractedText;
      notifyListeners();
    } catch (e) {
      lessonContent = "Erreur lors de la sélection du fichier : $e";
      notifyListeners();
    }
  }

  /// ✅ Extraction du texte d'un PDF
  Future<void> extractTextFromPDF(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception("Le fichier n'existe pas.");
      }

      List<int> bytes = await file.readAsBytes();
      PdfDocument document = PdfDocument(inputBytes: bytes);
      String extractedText = PdfTextExtractor(document).extractText();
      document.dispose(); // Libérer la mémoire

      if (extractedText.trim().isEmpty) {
        throw Exception("Aucun texte trouvé dans le PDF.");
      }

      lessonContent = extractedText;
      notifyListeners();
    } catch (e) {
      lessonContent = "Échec de l'extraction du texte. Erreur : $e";
      notifyListeners();
    }
  }

  /// ✅ Convertir le texte en audio TTS et enregistrer en fichier
  Future<String> generateAudioFromText() async {
    return await _lessonRepository.generateAudioFromText(lessonContent);
  }

  /// ✅ Générer une image à partir du texte
  Future<String> generateImageFromText(String text, int index) async {
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
  }

  /// ✅ Générer toutes les images depuis le texte
  Future<List<String>> generateImagesFromText() async {
    return await _lessonRepository.generateImagesFromText(lessonContent);
  }

  /// ✅ Générer une vidéo à partir des images
  Future<void> generateVideoFromImages() async {
    isProcessing = true;
    notifyListeners();

    try {
      List<String> imagePaths = await generateImagesFromText();
      String videoPath = await _lessonRepository.generateVideoFromImages(imagePaths);
      print("✅ Vidéo générée avec succès : $videoPath");
    } catch (e) {
      print("❌ Erreur lors de la génération vidéo : $e");
    }

    isProcessing = false;
    notifyListeners();
  }

  /// ✅ Ajouter l'audio TTS à la vidéo
  Future<void> addAudioToVideo() async {
    try {
      String audioPath = await generateAudioFromText();
      List<String> imagePaths = await generateImagesFromText();
      String videoPath = await _lessonRepository.generateVideoFromImages(imagePaths);
      String finalVideoPath = await _lessonRepository.addAudioToVideo(audioPath, videoPath);
      print("✅ Vidéo finale avec audio : $finalVideoPath");
    } catch (e) {
      print("❌ Erreur lors de l'ajout audio à la vidéo : $e");
    }
  }
}
