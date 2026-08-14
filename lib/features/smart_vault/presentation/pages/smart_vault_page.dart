import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_breakpoints.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/document_category.dart';
import '../../domain/vault_exception.dart';
import '../controllers/upload_document_controller.dart';
import '../controllers/vault_search_controller.dart';
import '../dialogs/upload_document_sheet.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/vault_document_list.dart';
import '../widgets/vault_search_bar.dart';

const _supportedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

/// Smart Vault home: search bar, category filter chips, the reactive
/// document list, and the upload FAB. Owns only ephemeral UI selection
/// state locally (which chip is selected, the search box's text) --
/// everything about the actual vault data flows through the existing
/// providers/controllers from Steps 3-4, never touched directly here.
class SmartVaultPage extends ConsumerStatefulWidget {
  const SmartVaultPage({super.key});

  @override
  ConsumerState<SmartVaultPage> createState() => _SmartVaultPageState();
}

class _SmartVaultPageState extends ConsumerState<SmartVaultPage> {
  final _searchController = TextEditingController();
  DocumentCategory? _selectedCategory;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() => _isSearching = query.isNotEmpty);
    if (query.isEmpty) {
      ref.read(vaultSearchControllerProvider.notifier).clear();
    } else {
      ref.read(vaultSearchControllerProvider.notifier).search(query);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _supportedExtensions,
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    if (!mounted) return;

    // TEMPORARY DEV LOGGING -- diagnosing why uploads never reach Supabase.
    // Remove once resolved.
    debugPrint('[UPLOAD] File picked: ${file.name}, size: ${bytes.length} bytes');

    final fileType = (file.extension ?? '').toLowerCase();
    final dotIndex = file.name.lastIndexOf('.');
    final suggestedTitle = dotIndex > 0 ? file.name.substring(0, dotIndex) : file.name;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UploadDocumentSheet(
        fileBytes: bytes,
        fileType: fileType,
        suggestedTitle: suggestedTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = context.screenSize.width;
    final horizontalPadding = AppBreakpoints.isDesktop(width) ? AppSpacing.xl : AppSpacing.md;

    ref.listen(uploadDocumentControllerProvider, (previous, next) {
      if (next.hasError) {
        final error = next.error;
        final message = error is VaultException ? error.message : AppStrings.genericErrorMessage;
        Helpers.showSnackBar(context, message);
      } else if (previous?.isLoading == true && next.hasValue && next.value != null) {
        Helpers.showSnackBar(context, 'Document uploaded successfully.');
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(title: 'Smart Vault'),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        tooltip: 'Upload document',
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, AppSpacing.md, horizontalPadding, 0),
                child: VaultSearchBar(controller: _searchController, onChanged: _onSearchChanged),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!_isSearching)
                CategoryFilterChips(
                  selected: _selectedCategory,
                  onSelected: (category) => setState(() => _selectedCategory = category),
                ),
              Expanded(
                child: VaultDocumentList(
                  isSearching: _isSearching,
                  searchQuery: _searchController.text.trim(),
                  selectedCategory: _selectedCategory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
