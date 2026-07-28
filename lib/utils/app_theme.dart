import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xffF8F9FD),
    textTheme: GoogleFonts.poppinsTextTheme(),
    colorSchemeSeed: Colors.orange,
  );
}