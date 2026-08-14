import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_spacing.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_type.dart';
import '../controllers/reminder_controller.dart';
import '../state/reminder_status.dart';
import '../utils/reminder_list_extensions.dart';
import '../validators/reminder_validator.dart';
import '../widgets/notification_enabled_switch.dart';
import '../widgets/reminder_date_time_field.dart';
import '../widgets/repeat_type_dropdown.dart';

/// Reached from a reminder's card overflow menu or its Details Screen.
/// Looks the reminder up in [reminderControllerProvider]'s already-live
/// `reminders` list (kept in sync by the Realtime stream since Phase 3) --
/// no extra fetch needed. The document a reminder is about is not editable
/// here (see `ReminderDocumentPicker`'s doc comment for why one is chosen
/// at creation time at all); everything else is.
class EditReminderPage extends ConsumerWidget {
  const EditReminderPage({required this.reminderId, super.key});

  final String reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderControllerProvider);
    final reminder = state.reminders.findById(reminderId);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Reminder'),
      body: reminder == null
          ? (state.isLoading
              ? const LoadingIndicator()
              : const EmptyStateWidget(
                  title: 'Reminder not found',
                  message: 'It may have been deleted.',
                  icon: Icons.event_busy,
                ))
          // Keyed by ID so this inner widget's State survives outer
          // rebuilds (a new `reminder` object arrives on every background
          // stream update) without resetting -- an edit in progress must
          // not be clobbered by an unrelated realtime refresh.
          : _EditReminderForm(key: ValueKey(reminderId), reminder: reminder),
    );
  }
}

class _EditReminderForm extends ConsumerStatefulWidget {
  const _EditReminderForm({required this.reminder, super.key});

  final Reminder reminder;

  @override
  ConsumerState<_EditReminderForm> createState() => _EditReminderFormState();
}

class _EditReminderFormState extends ConsumerState<_EditReminderForm> {
  late final _titleController = TextEditingController(text: widget.reminder.title);
  late final _descriptionController = TextEditingController(text: widget.reminder.description ?? '');
  late DateTime _scheduledAt = widget.reminder.scheduledAt;
  late RepeatType _repeatType = widget.reminder.repeatType;
  late bool _notificationEnabled = widget.reminder.notificationEnabled;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
    await ref.read(reminderControllerProvider.notifier).updateReminder(
          reminderId: widget.reminder.id,
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
    Helpers.showSnackBar(context, 'Reminder updated.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(reminderControllerProvider.select((s) => s.status == ReminderStatus.loading));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          PrimaryButton(label: 'Save Changes', isLoading: isSaving, onPressed: _submit),
        ],
      ),
    );
  }
}
