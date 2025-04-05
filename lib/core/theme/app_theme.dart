import 'package:flutter/material.dart';

class AppTheme {
  static const Color secondaryColor = Color(0xFF58CC02);
  static const Color primaryColor = Color(0xFF1CB0F6);
  static const Color accentColor = Color(0xFFFF9600);
  static const Color errorColor = Color(0xFFFF4B4B);
  static const Color backgroundColor = Color(0xFFF0F2F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF6F6F6F);
  static const Color textSecondaryColor = Color(0xFF6F6F6F);

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
  );
}