import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class LessonViewModel extends ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
  late String lessonContent = "";
  bool isProcessing = false;

  /// ✅ Sélectionner un fichier PDF et extraire le texte
  Future<void> pickAndExtractText() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        await extractTextFromPDF(filePath);
      } else {
        lessonContent = "Aucun fichier sélectionné.";
        notifyListeners();
      }
    } catch (e) {
      lessonContent = "Erreur lors de la sélection du fichier : $e";
      notifyListeners();
    }
  }

  /// ✅ Extraction du texte d’un PDF
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
    final directory = await getApplicationDocumentsDirectory();
    final audioPath = "${directory.path}/speech.mp3";

    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.synthesizeToFile(lessonContent, audioPath);

    return audioPath;
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
    List<String> imagePaths = [];
    List<String> textPages = lessonContent.split("\n\n");

    for (int i = 0; i < textPages.length; i++) {
      String path = await generateImageFromText(textPages[i], i);
      imagePaths.add(path);
    }

    return imagePaths;
  }

  /// ✅ Générer une vidéo à partir des images
  Future<void> generateVideoFromImages() async {
    isProcessing = true;
    notifyListeners();

    try {
      List<String> imagePaths = await generateImagesFromText();
      final directory = await getApplicationDocumentsDirectory();
      String imageListFile = "${directory.path}/images.txt";
      File(imageListFile).writeAsStringSync(
          imagePaths.map((path) => "file '$path'").join("\n"));

      final String videoPath = "${directory.path}/output_video.mp4";

      await FFmpegKit.execute(
          "-f concat -safe 0 -i $imageListFile -vf fps=1 -y $videoPath");

      print("✅ Vidéo générée avec succès : $videoPath");
    } catch (e) {
      print("❌ Erreur lors de la génération vidéo : $e");
    }

    isProcessing = false;
    notifyListeners();
  }

  /// ✅ Ajouter l’audio TTS à la vidéo
  Future<void> addAudioToVideo() async {
    String audioPath = await generateAudioFromText();
    final directory = await getApplicationDocumentsDirectory();
    String videoPath = "${directory.path}/output_video.mp4";
    String finalVideoPath = "${directory.path}/final_video.mp4";

    await FFmpegKit.execute(
        '-i $videoPath -i $audioPath -c:v copy -c:a aac -strict experimental -shortest -y $finalVideoPath');

    print("✅ Vidéo finale avec audio : $finalVideoPath");
  }
}
