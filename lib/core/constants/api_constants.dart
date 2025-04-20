import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
<<<<<<< Updated upstream
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://1a1d-197-23-203-147.ngrok-free.app';
=======
  // 10.0.2.2 is the special alias to host machine's localhost in Android emulator
  static String get baseUrl => 'http://10.0.2.2:3000';
>>>>>>> Stashed changes
}
