import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/vault_document.dart';
import '../controllers/rename_document_controller.dart';

/// Material dialog for renaming a document via [RenameDocumentController].
/// Pops itself on success; the caller (`DocumentDetailsPage`) doesn't need
/// to do anything else -- the controller already invalidates
/// `documentByIdProvider` for this document on a successful rename, so the
/// details page picks up the new title on its own.
class RenameDocumentDialog extends ConsumerStatefulWidget {
  const RenameDocumentDialog({required this.document, super.key});

  final VaultDocument document;

  @override
  ConsumerState<RenameDocumentDialog> createState() => _RenameDocumentDialogState();
}

class _RenameDocumentDialogState extends ConsumerState<RenameDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.document.title);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(renameDocumentControllerProvider.notifier).rename(
          documentId: widget.document.documentId,
          newTitle: _titleController.text.trim(),
        );
    if (!mounted) return;
    if (!ref.read(renameDocumentControllerProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final renameState = ref.watch(renameDocumentControllerProvider);

    return AlertDialog(
      title: const Text('Rename Document'),
      content: Form(
        key: _formKey,
        child: CustomTextField(
          label: 'Title',
          controller: _titleController,
          validator: (value) => Validators.required(value, fieldName: 'Title'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: renameState.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          label: 'Save',
          fullWidth: false,
          isLoading: renameState.isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
