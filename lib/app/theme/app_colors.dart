import 'package:flutter/material.dart';

/// Brand color palette used to seed the Material 3 color schemes.
///
/// Individual screens should read colors from `Theme.of(context).colorScheme`
/// rather than this class directly, so light/dark mode is respected.
class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF3A5AFF);

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE0A32C);
  static const Color danger = Color(0xFFD64545);

  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color darkBackground = Color(0xFF121319);
}
