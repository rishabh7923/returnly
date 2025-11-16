import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Simple white and grey palette
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);
  static const Color almostBlack = Color(0xFF212121);

  static ThemeData lightTheme = ThemeData(
    fontFamily: GoogleFonts.roboto().fontFamily,
    brightness: Brightness.light,
    scaffoldBackgroundColor: pureWhite,
    primaryColor: darkGrey,
    colorScheme: ColorScheme.light(
      primary: darkGrey,
      secondary: mediumGrey,
      surface: pureWhite,
      background: pureWhite,
      error: Colors.red,
      onPrimary: pureWhite,
      onSecondary: pureWhite,
      onSurface: almostBlack,
      onBackground: almostBlack,
    ),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      backgroundColor: lightGrey,
      titleTextStyle: TextStyle(
        color: almostBlack,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),
      iconTheme: IconThemeData(color: almostBlack),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: pureWhite,
      elevation: 2,
      shadowColor: mediumGrey.withOpacity(0.2),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontSize: 18, color: almostBlack),
      bodyMedium: TextStyle(fontSize: 16, color: darkGrey),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: almostBlack,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: darkGrey,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightGrey,
      labelStyle: TextStyle(color: darkGrey, fontSize: 12),
      side: BorderSide(color: mediumGrey.withOpacity(0.3)),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkGrey,
      foregroundColor: pureWhite,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkGrey,
        foregroundColor: pureWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconTheme: IconThemeData(color: darkGrey),
    dividerColor: mediumGrey.withOpacity(0.3),
  );
}
