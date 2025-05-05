import 'dart:io';
import 'dart:ui' as ui;
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/eleven_labs_service.dart';



class LessonViewModel extends ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
  final ElevenLabsService elevenLabsService = ElevenLabsService();

  String lessonContent = "";
  bool isProcessing = false;
  String? generatedVideoPath;

  Future<void> requestStoragePermission() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      print("Permission to access storage denied.");
    }
  }

  Future<void> pickAndExtractText() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        await extractTextFromPDF(result.files.single.path!);
      } else {
        lessonContent = "Aucun fichier sélectionné.";
        notifyListeners();
      }
    } catch (e) {
      lessonContent = "Erreur lors de la sélection du fichier : $e";
      notifyListeners();
    }
  }

  Future<void> extractTextFromPDF(String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception("Le fichier n'existe pas.");
      }

      List<int> bytes = await file.readAsBytes();
      PdfDocument document = PdfDocument(inputBytes: bytes);
      String extractedText = PdfTextExtractor(document).extractText();
      document.dispose();

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

  List<String> _splitTextIntoPages(String text) {
    List<String> pages = [];
    const int maxLength = 800;
    int start = 0;

    while (start < text.length) {
      int end = (start + maxLength) < text.length ? start + maxLength : text.length;
      pages.add(text.substring(start, end));
      start = end;
    }

    return pages;
  }

  Future<String> generateImageFromText(String text, int index) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(const Offset(0, 0), const Offset(900, 600)));

    final paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 900, 600), paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: 850);
    textPainter.paint(canvas, const Offset(25, 250));

    final picture = recorder.endRecording();
    final img = await picture.toImage(900, 600);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Erreur lors de la conversion de l'image en bytes.");
    }

    final buffer = byteData.buffer.asUint8List();
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = "${directory.path}/page_${index.toString().padLeft(2, '0')}.png";
    final file = File(imagePath);
    await file.writeAsBytes(buffer);

    try {
      await Gal.putImage(imagePath);
    } catch (e) {
      print("Erreur lors de l'enregistrement de l'image dans la galerie : $e");
    }

    return imagePath;
  }

  Future<void> generateMultipleImagesFromText() async {
    List<String> textPages = _splitTextIntoPages(lessonContent);

    for (int i = 0; i < textPages.length; i++) {
      await generateImageFromText(textPages[i], i);
    }

    notifyListeners();
  }

  Future<String> generateAudioFromText() async {
    try {
      final audioPath = await elevenLabsService.generateAudioFromText(lessonContent, 'lesson_audio');
      print("✅ Audio généré à : $audioPath");
      return audioPath;
    } catch (e) {
      print("❌ Erreur lors de la génération de l’audio : $e");
      rethrow;
    }
  }

  Future<void> generateVideoFromImages() async {
    isProcessing = true;
    notifyListeners();

    try {
      await generateMultipleImagesFromText();
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = "${directory.path}/output_video.mp4";
      final audioPath = await generateAudioFromText();

      String ffmpegCommand =
          "-framerate 1/3 -start_number 0 -i '${directory.path}/page_%02d.png' "
          "-i '$audioPath' -c:v mpeg4 -r 30 -pix_fmt yuv420p "
          "-c:a aac -shortest -y '$videoPath'";

      await FFmpegKit.execute(ffmpegCommand).then((session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          print("✅ Vidéo avec audio générée !");
          await Gal.putVideo(videoPath);
          generatedVideoPath = videoPath;
        } else {
          print("❌ Échec de la génération de la vidéo avec audio.");
        }
      });

    } catch (e) {
      lessonContent = "Erreur lors de la génération vidéo/audio : $e";
      print("❌ Erreur : $e");
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
	