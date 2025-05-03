import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConstants {

  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    
    // If environment URL is set, use it
    if (envUrl != null && envUrl.isNotEmpty) {
      // For Android emulator, replace localhost with 10.0.2.2
      if (!kIsWeb && Platform.isAndroid) {
        return envUrl.replaceAll('localhost', '10.0.2.2')
                    .replaceAll('127.0.0.1', '10.0.2.2');
      }
      return envUrl;
    }
    
    // Default URLs based on platform
    if (!kIsWeb) {
      // For Android emulator
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
      // For iOS simulator
      return 'http://localhost:3000';
    }
    
    // For web
    return 'http://localhost:3000';
  }

}


