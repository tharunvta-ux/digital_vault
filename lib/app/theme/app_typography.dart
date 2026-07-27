import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized text theme so typography stays consistent across the app.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return GoogleFonts.interTextTheme(base);
  }
}
