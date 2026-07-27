import 'package:flutter/material.dart';

import '../../../../core/utils/app_spacing.dart';

/// Shared page shell for Login/Register/Forgot-Password so the three pages
/// don't triplicate the same Scaffold/SafeArea/ScrollView boilerplate.
///
/// The bare [AppBar] carries no title — its only job is to supply the
/// automatic back chevron on pages reached via `context.push` (Register,
/// Forgot Password); Login, which nothing is pushed on top of, simply shows
/// none.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
