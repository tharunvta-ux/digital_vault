import 'package:flutter/material.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../domain/entities/vault_document.dart';
import '../pages/document_details_page.dart';
import 'vault_document_card.dart';

/// Pure list rendering -- no provider reads, no async state. Responsive via
/// a `GridView.builder` (unlike the dashboard's fixed 4 stats, this list is
/// variable-length and needs real lazy building/scrolling, so `GridView`
/// is the right tool here rather than the manual Row/Expanded chunking used
/// for the dashboard's small fixed count).
class VaultDocumentListView extends StatelessWidget {
  const VaultDocumentListView({required this.documents, super.key});

  final List<VaultDocument> documents;

  @override
  Widget build(BuildContext context) {
    final columns = AppBreakpoints.columnsFor(context.screenSize.width, phoneColumns: 1, wideColumns: 2);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 104,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return VaultDocumentCard(
          document: document,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DocumentDetailsPage(documentId: document.documentId)),
          ),
        );
      },
    );
  }
}
