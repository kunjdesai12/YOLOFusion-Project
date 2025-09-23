import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 Color Constants
  static const Color primaryBlue = Color(0xFF0074D9);      // CTA Bright Blue
  static const Color pastelBlue = Color(0xFFE6F0FA);       // Background Soft Blue
  static const Color backgroundLight = Color(0xFFF8F9FA);  // Scaffold Background
  static const Color textDark = Color(0xFF1A2E44);         // Deep Navy Text
  static const Color textMuted = Color(0xFF6C757D);        // Muted Gray Text
  static const Color errorColor = Color(0xFFD32F2F);       // Optional Red for Errors
  static const Color dividerColor = Color(0xFFD3D3D3);     // Light Gray for Dividers
  static const Color textPrimary = textDark;               // Alias for textDark

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryBlue,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: pastelBlue,
        background: backgroundLight,
        error: errorColor,
        brightness: Brightness.light,
      ),

      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary, // Updated to use textPrimary
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary, // Updated to use textPrimary
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textDark,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pastelBlue,
        labelStyle: TextStyle(color: textMuted),
        prefixIconColor: primaryBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),

      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 8,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 32,
      ),
    );
  }
}