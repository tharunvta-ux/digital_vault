import 'package:flutter/material.dart';

/// Centered title placeholder used by feature screens that haven't been
/// implemented yet. Replace with the real screen as each module lands.
class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({required this.title, this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true, actions: actions),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
