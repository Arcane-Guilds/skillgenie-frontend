import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTheme {
  static const Color secondaryColor = Color(0xFF58CC02);
  static const Color primaryColor = Color(0xFF1CB0F6);
  static const Color accentColor = Color(0xFFFF9600);
  static const Color errorColor = Color(0xFFFF4B4B);
  static const Color backgroundColor = Color(0xFFF0F2F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF6F6F6F);
  static const Color textSecondaryColor = Color(0xFF6F6F6F);

  // Web-specific colors
  static const Color webBackgroundColor = Color(0xFFF7F9FA);
  static const Color webSurfaceColor = Colors.white;
  static const Color webBorderColor = Color(0xFFE0E0E0);

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(kIsWeb ? 8 : 16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(kIsWeb ? 0.03 : 0.05),
        blurRadius: kIsWeb ? 6 : 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: kIsWeb ? Border.all(color: webBorderColor, width: 1) : null,
  );

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: kIsWeb ? webBackgroundColor : backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: kIsWeb ? webSurfaceColor : surfaceColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: kIsWeb ? 0 : 1,
      iconTheme: IconThemeData(color: textPrimaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: kIsWeb ? 22 : 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: kIsWeb ? 32 : 24, 
          vertical: kIsWeb ? 16 : 12
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kIsWeb ? 6 : 30),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kIsWeb ? Colors.white : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 12),
        borderSide: BorderSide(
          color: kIsWeb ? webBorderColor : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 12),
        borderSide: BorderSide(
          color: kIsWeb ? webBorderColor : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 8 : 12),
        borderSide: const BorderSide(
          color: primaryColor,
          width: kIsWeb ? 1.5 : 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: kIsWeb ? 16 : 12
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: kIsWeb ? 32 : 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: kIsWeb ? 28 : 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: kIsWeb ? 16 : 14,
        color: textPrimaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: kIsWeb ? 14 : 12,
        color: textSecondaryColor,
      ),
    ),
  );
}