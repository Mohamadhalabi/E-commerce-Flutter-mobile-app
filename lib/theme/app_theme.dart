import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts here
import '../constants.dart';

class AppTheme {
  // --------------------------------------
  // LIGHT THEME
  // --------------------------------------
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryColor,
      primarySwatch: primaryMaterialColor,

      // ✅ APPLY POPPINS FONT HERE
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme,
      ),

      // Setup AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
      ),

      // Setup Input Decoration (TextFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGreyColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: greyColor, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
        ),
      ),
    );
  }

  // --------------------------------------
  // DARK THEME
  // --------------------------------------
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkGreyColor,
      primaryColor: primaryColor,
      primarySwatch: primaryMaterialColor,

      // ✅ APPLY POPPINS FONT HERE TOO
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101015), // Match scaffold background or slightly lighter
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}