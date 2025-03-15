import 'api_constants.dart';

class AuthConstants {
  static String get signup => '${ApiConstants.baseUrl}/auth/signup';
  static String get signin => '${ApiConstants.baseUrl}/auth/signin';
  static String get forgot_password => '${ApiConstants.baseUrl}/auth/forgot-password';
  static String get verify_otp => '${ApiConstants.baseUrl}/auth/verify-otp';
  static String get reset_password => '${ApiConstants.baseUrl}/auth/reset-password';
}