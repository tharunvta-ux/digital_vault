import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_text_field.dart';

/// A [CustomTextField] preconfigured for password entry, with a local
/// show/hide toggle. Composition over duplication — all actual field
/// styling still comes from the shared [CustomTextField].
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    required this.label,
    this.controller,
    this.validator,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscure,
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
