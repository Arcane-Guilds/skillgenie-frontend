import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ElevenLabsService {
  static const String apiKey = "sk_c0d677bb983be7eb4ffccffd0a0d6c7c6e452e1b3882dcbe";
  static const String baseUrl = "https://api.elevenlabs.io/v1/text-to-speech";

  // ID de voix par défaut — tu peux le modifier si tu veux une autre voix
  static const String voiceId = "21m00Tcm4TlvDq8ikWAM"; // Rachel

  Future<String> generateAudioFromText(String text, String filename) async {
    final url = Uri.parse('$baseUrl/$voiceId/stream');

    final headers = {
      'xi-api-key': apiKey, // ✅ c’est "xi-api-key", pas "Authorization"
      'Content-Type': 'application/json',
      'Accept': 'audio/mpeg', // Recommandé pour le stream audio
    };

    final data = {
      'text': text,
      'voice_settings': {
        'stability': 0.5,
        'similarity_boost': 0.5,
      },
    };

    try {
      final response = await http.post(url, headers: headers, body: json.encode(data));

      if (response.statusCode == 200) {
        final filePath = await _saveAudioToFile(response.bodyBytes, filename);
        return filePath;
      } else {
        print("❌ Failed to generate audio: ${response.statusCode} ${response.body}");
        throw Exception('Failed to generate audio: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print("❌ Error generating audio: $e");
      rethrow;
    }
  }

  Future<String> _saveAudioToFile(Uint8List audioBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename.mp3');
    await file.writeAsBytes(audioBytes);
    return file.path;
  }
  // ✅ New method: long text support
  Future<List<String>> generateAudioFromLongText(String longText, String filenamePrefix) async {
  const int maxChars = 500;  // Reduce chunk size to 500 characters to avoid exceeding limit
  List<String> filePaths = [];
  int part = 1;

  // Loop through the long text in chunks of maxChars size
  for (int i = 0; i < longText.length; i += maxChars) {
    String chunk = longText.substring(i, (i + maxChars > longText.length) ? longText.length : i + maxChars);
    try {
      String filePath = await generateAudioFromText(chunk, '$filenamePrefix-part$part');
      filePaths.add(filePath);
      part++;
    } catch (e) {
      print("Error generating audio for chunk $part: $e");
      throw Exception("Error generating audio for chunk $part");
    }
  }

  return filePaths;
}

}
	