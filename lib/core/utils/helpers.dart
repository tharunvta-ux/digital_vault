import 'package:flutter/material.dart';

/// Small, generic helper functions shared across features.
class Helpers {
  const Helpers._();

  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
