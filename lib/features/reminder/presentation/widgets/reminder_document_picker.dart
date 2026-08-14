import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../smart_vault/presentation/providers/vault_providers.dart';

/// Lets the user pick which vault document a new reminder is about.
/// `document_id` is a mandatory foreign key at the database level (see the
/// `reminders` table's schema), so a reminder cannot be created without
/// one. This widget's only job is picking an existing document, via Smart
/// Vault's existing, unmodified `watchAllDocumentsProvider` -- it never
/// writes anything back to Smart Vault. Deeper integration (e.g. launching
/// "Create Reminder" from a document's own detail page) stays out of scope
/// for this phase.
class ReminderDocumentPicker extends ConsumerWidget {
  const ReminderDocumentPicker({required this.value, required this.onChanged, super.key});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _decoration = InputDecoration(labelText: 'Document', border: OutlineInputBorder());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(watchAllDocumentsProvider);

    return documentsAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          return const InputDecorator(
            decoration: _decoration,
            child: Text('No documents in your vault yet. Upload one from Smart Vault first.'),
          );
        }
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: _decoration,
          items: [
            for (final document in documents)
              DropdownMenuItem(
                value: document.documentId,
                child: Text(document.title, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
          validator: (selected) => selected == null ? 'Please select a document.' : null,
        );
      },
      loading: () => const InputDecorator(
        decoration: _decoration,
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stackTrace) => InputDecorator(
        decoration: _decoration,
        child: Text(
          'Could not load your documents.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
