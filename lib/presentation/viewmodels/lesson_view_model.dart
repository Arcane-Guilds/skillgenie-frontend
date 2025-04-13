import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';


class LessonViewModel extends ChangeNotifier {
  final FlutterTts flutterTts = FlutterTts();
  String lessonContent = "";
  bool isProcessing = false;

  // Request storage permission
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
    final canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(900, 600)));

    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, 900, 600), paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.black, fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: 850);
    textPainter.paint(canvas, Offset(25, 250));

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
      await Gal.putImage(imagePath);  // Add image to gallery
    } catch (e) {
      print("Erreur lors de l'enregistrement de l'image dans la galerie : $e");
    }

    return imagePath;
  }

  Future<void> generateMultipleImagesFromText() async {
    List<String> imagePaths = [];
    List<String> textPages = lessonContent.split("\n\n");

    for (int i = 0; i < textPages.length; i++) {
      String path = await generateImageFromText(textPages[i], i);
      imagePaths.add(path);
    }
    notifyListeners();
  }

  Future<void> generateVideoFromImages() async {
    isProcessing = true;
    notifyListeners();

    try {
      await generateMultipleImagesFromText();

      final directory = await getApplicationDocumentsDirectory();
      final originalPath = "${directory.path}/page_00.png";

      if (File(originalPath).existsSync()) {
        for (int i = 1; i < 5; i++) {
          String newPath = "${directory.path}/page_${i.toString().padLeft(2, '0')}.png";
          File(originalPath).copySync(newPath);
          await Gal.putImage(newPath);  // Add copied image to gallery
        }
      } else {
        print("❌ L'image source n'existe pas !");
      }

      final videoPath = "${directory.path}/output_video.mp4";

      // FFmpeg command to create video from images
      String ffmpegCommand =
          "-framerate 1 -start_number 1 -i '${directory.path}/page_%02d.png' -c:v mpeg4 -r 30 -pix_fmt yuv420p -y '$videoPath'";

      await FFmpegKit.execute(ffmpegCommand).then((session) async {
        final returnCode = await session.getReturnCode();
        final logs = await session.getAllLogs();
        logs.forEach((log) => print("📋 LOG: ${log.getMessage()}"));

        if (ReturnCode.isSuccess(returnCode)) {
          print("✅ Vidéo générée avec succès !");
          // Add video to gallery
  await Gal.putVideo(videoPath);  // 👉 Ajouter cette ligne
        } else {
          print("❌ Échec de la génération de la vidéo.");
        }
      });

      // Check if video was successfully created
      if (!File(videoPath).existsSync()) {
        throw Exception("La vidéo n'a pas été générée correctement.");
      }

    } catch (e) {
      lessonContent = "Erreur lors de la génération de la vidéo : $e";
      print("❌ Erreur : $e");
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  // Add the video to the gallery
Future<void> addVideoToGallery(String videoPath) async {
if (await Permission.storage.request().isGranted) {
    // Permissions granted, proceed with the media scan.
  } else {
    // Handle permission denial.
    print('Storage permission is required.');
  }
}

Future<void> requestStoragePermissions() async {
  // Check if permission is already granted
  PermissionStatus status = await Permission.storage.status;
  
  if (!status.isGranted) {
    // If permission is not granted, request permission
    PermissionStatus result = await Permission.storage.request();
    
    if (result.isGranted) {
      // Permission granted, continue with your operation
      print("Storage permission granted");
    } else {
      // Handle the case where permission is denied
      print("Storage permission denied");
    }
  } else {
    // If permission is already granted, proceed
    print("Storage permission already granted");
  }
}


}
