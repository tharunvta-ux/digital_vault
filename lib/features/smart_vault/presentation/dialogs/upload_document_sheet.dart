import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/document_category.dart';
import '../controllers/upload_document_controller.dart';

/// Bottom sheet collecting a title and category for a file that's already
/// been picked, then submitting it via [UploadDocumentController]. Pops
/// itself once the upload succeeds; success/error feedback (the snackbar)
/// is the caller's job -- see `SmartVaultPage`'s `ref.listen` -- so this
/// sheet only needs to know "did it work, should I close."
class UploadDocumentSheet extends ConsumerStatefulWidget {
  const UploadDocumentSheet({
    required this.fileBytes,
    required this.fileType,
    required this.suggestedTitle,
    super.key,
  });

  final Uint8List fileBytes;
  final String fileType;
  final String suggestedTitle;

  @override
  ConsumerState<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.suggestedTitle);
  DocumentCategory _category = DocumentCategory.other;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(uploadDocumentControllerProvider.notifier).upload(
          title: _titleController.text.trim(),
          category: _category,
          fileType: widget.fileType,
          fileBytes: widget.fileBytes,
        );
    if (!mounted) return;
    if (!ref.read(uploadDocumentControllerProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadDocumentControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Upload Document', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            CustomTextField(
              label: 'Title',
              controller: _titleController,
              validator: (value) => Validators.required(value, fieldName: 'Title'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<DocumentCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: [
                for (final category in DocumentCategory.values)
                  DropdownMenuItem(value: category, child: Text(category.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Upload',
              isLoading: uploadState.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
