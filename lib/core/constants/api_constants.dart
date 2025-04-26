import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {

  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.128.1:3000';

}
