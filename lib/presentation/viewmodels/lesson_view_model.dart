import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';


import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';

class LessonViewModel extends ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
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
    List<String> imagePaths = [];
    List<String> textPages = _splitTextIntoPages(lessonContent);

    for (int i = 0; i < textPages.length; i++) {
      String path = await generateImageFromText(textPages[i], i);
      imagePaths.add(path);
    }

    notifyListeners();
  }

  List<String> _splitTextIntoPages(String text) {
    // You can split your content more intelligently here based on the PDF structure.
    // For example, splitting by paragraphs or chunks of text, etc.
    List<String> pages = [];
    const int maxLength = 800; // Max characters per page
    int start = 0;

    while (start < text.length) {
      int end = (start + maxLength) < text.length ? start + maxLength : text.length;
      pages.add(text.substring(start, end));
      start = end;
    }

    return pages;
  }

  Future<void> generateVideoFromImages() async {
    isProcessing = true;
    notifyListeners();

    try {
      await generateMultipleImagesFromText();

      final directory = await getApplicationDocumentsDirectory();
      List<String> generatedImages = [];

      for (int i = 0; i < 4; i++) {
        String imagePath = "${directory.path}/page_${i.toString().padLeft(2, '0')}.png";
        if (File(imagePath).existsSync()) {
          generatedImages.add(imagePath);
        }
      }

      if (generatedImages.length == 4) {
        final videoPath = "${directory.path}/output_video.mp4";
        String ffmpegCommand =
            "-framerate 1/3 -start_number 1 -i '${directory.path}/page_%02d.png' -c:v mpeg4 -r 30 -pix_fmt yuv420p -y '$videoPath'";

        await FFmpegKit.execute(ffmpegCommand).then((session) async {
          final returnCode = await session.getReturnCode();

          if (ReturnCode.isSuccess(returnCode)) {
            print("✅ Vidéo générée avec succès !");
            await Gal.putVideo(videoPath);
            generatedVideoPath = videoPath;
          } else {
            print("❌ Échec de la génération de la vidéo.");
          }
        });
      } else {
        print("❌ Moins de 4 images générées, vidéo non créée.");
      }

    } catch (e) {
      lessonContent = "Erreur lors de la génération de la vidéo : $e";
      print("❌ Erreur : $e");
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
