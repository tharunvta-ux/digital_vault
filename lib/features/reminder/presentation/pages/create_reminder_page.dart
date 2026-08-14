import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../smart_vault/presentation/providers/vault_providers.dart';
import '../../domain/entities/repeat_type.dart';
import '../controllers/reminder_controller.dart';
import '../state/reminder_status.dart';
import '../validators/reminder_validator.dart';
import '../widgets/notification_enabled_switch.dart';
import '../widgets/reminder_date_time_field.dart';
import '../widgets/reminder_document_picker.dart';
import '../widgets/repeat_type_dropdown.dart';

/// Reached via the Reminder List Screen's floating action button, or from
/// Smart Vault (Document Details / a document card's overflow menu) with
/// [documentId] already known. Collects every field `CreateReminderUseCase`
/// needs and submits through [reminderControllerProvider] -- this screen
/// holds no business rules of its own; `ReminderValidator` is the only
/// source of title/date/time/repeat validation, called once at submit time.
/// The document picker's own "please select a document" check is the one
/// field `ReminderValidator` was never scoped to cover (see
/// `ReminderDocumentPicker`'s doc comment).
class CreateReminderPage extends ConsumerStatefulWidget {
  const CreateReminderPage({this.documentId, super.key});

  /// Pre-selects and locks the reminder's document -- set when reached from
  /// Smart Vault, where the document is already known and the user should
  /// never have to pick it again. `null` only for the Reminder List
  /// Screen's own FAB, which has no document context and shows the picker
  /// instead.
  final String? documentId;

  @override
  ConsumerState<CreateReminderPage> createState() => _CreateReminderPageState();
}

class _CreateReminderPageState extends ConsumerState<CreateReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(minutes: 15));
  RepeatType _repeatType = RepeatType.once;
  bool _notificationEnabled = true;
  late String? _documentId = widget.documentId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final validationError = ReminderValidator.validate(
      title: _titleController.text,
      scheduledAt: _scheduledAt,
      repeatType: _repeatType,
    );
    if (validationError != null) {
      Helpers.showSnackBar(context, validationError);
      return;
    }

    final description = _descriptionController.text.trim();
    await ref.read(reminderControllerProvider.notifier).createReminder(
          documentId: _documentId!,
          title: _titleController.text.trim(),
          description: description.isEmpty ? null : description,
          scheduledAt: _scheduledAt,
          repeatType: _repeatType,
          notificationEnabled: _notificationEnabled,
        );

    if (!mounted) return;
    final state = ref.read(reminderControllerProvider);
    if (state.hasError) {
      Helpers.showSnackBar(context, state.errorMessage ?? AppStrings.genericErrorMessage);
      return;
    }
    Helpers.showSnackBar(context, 'Reminder created.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(reminderControllerProvider.select((s) => s.status == ReminderStatus.loading));
    // A locked document (passed in from Smart Vault) is already known to
    // exist -- no need to wait on or check the full vault list for it.
    final hasDocuments =
        widget.documentId != null || (ref.watch(watchAllDocumentsProvider).valueOrNull?.isNotEmpty ?? false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Create Reminder'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.documentId != null)
                _LockedDocumentField(documentId: widget.documentId!)
              else
                ReminderDocumentPicker(
                  value: _documentId,
                  onChanged: (value) => setState(() => _documentId = value),
                ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'Title', controller: _titleController),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(label: 'Description', controller: _descriptionController, maxLines: 4),
              const SizedBox(height: AppSpacing.md),
              ReminderDateTimeField(
                value: _scheduledAt,
                onChanged: (value) => setState(() => _scheduledAt = value),
              ),
              const SizedBox(height: AppSpacing.md),
              RepeatTypeDropdown(
                value: _repeatType,
                onChanged: (value) => setState(() => _repeatType = value),
              ),
              NotificationEnabledSwitch(
                value: _notificationEnabled,
                onChanged: (value) => setState(() => _notificationEnabled = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Create Reminder',
                isLoading: isSaving,
                onPressed: hasDocuments ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only stand-in for [ReminderDocumentPicker] when [CreateReminderPage]
/// was reached with a document already chosen -- shows which document this
/// reminder is for, without letting it be changed.
class _LockedDocumentField extends ConsumerWidget {
  const _LockedDocumentField({required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(documentByIdProvider(documentId)).valueOrNull?.title;
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Document', border: OutlineInputBorder()),
      child: Text(title ?? 'Loading...'),
    );
  }
}
