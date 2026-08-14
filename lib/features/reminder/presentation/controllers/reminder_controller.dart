import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_type.dart';
import '../../domain/reminder_exception.dart';
import '../providers/reminder_providers.dart';
import '../state/reminder_state.dart';
import '../state/reminder_status.dart';
import '../utils/reminder_document_lookup.dart';
import '../utils/reminder_list_extensions.dart';
import '../validators/reminder_validator.dart';

/// Owns every Smart Reminder read/write the presentation layer needs.
/// Only ever calls through the usecases built in Phase 2 -- never touches
/// `ReminderRepository`/`ReminderRemoteDataSource` directly, so this stays
/// the one place any future UI has to go through.
///
/// One controller, one [ReminderState], covering the list, the selected
/// reminder, and whichever single operation is in flight -- not a separate
/// `AsyncNotifier` per action the way Smart Vault's upload/rename/delete
/// controllers are split. The real consequence of that choice: a create in
/// flight and a list still loading both show as [ReminderStatus.loading],
/// since there's only one status field for the whole feature. That's the
/// explicitly requested shape for this feature, not an oversight.
class ReminderController extends Notifier<ReminderState> {
  @override
  ReminderState build() {
    // Supplies `state.reminders`' initial snapshot (and would keep it live
    // afterward, the same "Notifier wraps a StreamProvider via ref.listen"
    // pattern already used by RecoveryFailureReasonNotifier in the
    // authentication feature -- except the `reminders` table has no
    // Realtime publication enabled, so in practice no further event ever
    // arrives here after the first one. Every write method below patches
    // `state.reminders` itself for exactly that reason; this listener is
    // not a substitute for that. `ref.listen` can only be called during a
    // provider's build phase, so this subscription setup lives here, not
    // inside `watchReminders()`.
    ref.listen(watchRemindersProvider, (previous, next) {
      next.when(
        data: (reminders) {
          state = state.copyWith(
            status: ReminderStatus.success,
            reminders: reminders,
            clearErrorMessage: true,
          );
        },
        loading: () {
          // Only show a loading state for the very first load -- once a
          // list is already on screen, a stream reconnect shouldn't blank
          // it back to a spinner.
          if (state.status == ReminderStatus.initial) {
            state = state.copyWith(status: ReminderStatus.loading);
          }
        },
        error: (error, stackTrace) {
          state = state.copyWith(status: ReminderStatus.error, errorMessage: _messageFor(error));
        },
      );
    });
    return const ReminderState();
  }

  /// The live subscription is already established in [build] -- simply
  /// creating or watching this controller starts it. This method exists so
  /// a screen has an explicit "start watching" entry point to call on
  /// mount (matching the method list this phase was scoped to) and gets
  /// immediate loading feedback rather than waiting for the first stream
  /// event to arrive.
  void watchReminders() {
    if (state.status == ReminderStatus.initial) {
      state = state.copyWith(status: ReminderStatus.loading);
    }
  }

  Future<void> createReminder({
    required String documentId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) async {
    final validationError = ReminderValidator.validate(
      title: title,
      scheduledAt: scheduledAt,
      repeatType: repeatType,
    );
    if (validationError != null) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: validationError);
      return;
    }

    state = state.copyWith(status: ReminderStatus.loading);
    try {
      final reminder = await ref.read(createReminderUseCaseProvider)(
        documentId: documentId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        repeatType: repeatType,
        notificationEnabled: notificationEnabled,
      );
      state = state.copyWith(
        status: ReminderStatus.success,
        selectedReminder: reminder,
        reminders: [...state.reminders, reminder],
        clearErrorMessage: true,
      );
      await _scheduleNotification(reminder);
    } catch (error) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: _messageFor(error));
    }
  }

  Future<void> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) async {
    final validationError = ReminderValidator.validate(
      title: title,
      scheduledAt: scheduledAt,
      repeatType: repeatType,
    );
    if (validationError != null) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: validationError);
      return;
    }

    state = state.copyWith(status: ReminderStatus.loading);
    try {
      final reminder = await ref.read(updateReminderUseCaseProvider)(
        reminderId: reminderId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        repeatType: repeatType,
        notificationEnabled: notificationEnabled,
      );
      state = state.copyWith(
        status: ReminderStatus.success,
        selectedReminder: reminder,
        reminders: state.reminders.replacingById(reminder),
        clearErrorMessage: true,
      );
      await _updateNotification(reminder);
    } catch (error) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: _messageFor(error));
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    state = state.copyWith(status: ReminderStatus.loading);
    try {
      await ref.read(deleteReminderUseCaseProvider)(reminderId);
      state = state.copyWith(
        status: ReminderStatus.success,
        reminders: state.reminders.removingById(reminderId),
        clearSelectedReminder: true,
        clearErrorMessage: true,
      );
      await _cancelNotification(reminderId);
    } catch (error) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: _messageFor(error));
    }
  }

  Future<void> getReminderById(String reminderId) async {
    state = state.copyWith(status: ReminderStatus.loading);
    try {
      final reminder = await ref.read(getReminderUseCaseProvider)(reminderId);
      state = state.copyWith(
        status: ReminderStatus.success,
        selectedReminder: reminder,
        clearErrorMessage: true,
      );
    } catch (error) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: _messageFor(error));
    }
  }

  /// Marks a reminder done.
  Future<void> setReminderCompleted(String reminderId) => _setCompleted(reminderId, true);

  /// The opposite of [setReminderCompleted] -- both are the same
  /// underlying usecase with a different `completed` value, since marking
  /// done and reopening are the same kind of edit, not two different
  /// features.
  Future<void> reopenReminder(String reminderId) => _setCompleted(reminderId, false);

  Future<void> _setCompleted(String reminderId, bool completed) async {
    // Captured before the write, not re-derived from `state.reminders`
    // afterward -- there's no Realtime push coming for this change (see
    // `ReminderListLookup`'s doc comment), and this is the only place that
    // knows both "which reminder" and "what its fields were" without a
    // second Supabase read.
    final reminder = state.reminders.findById(reminderId);
    state = state.copyWith(status: ReminderStatus.loading);
    try {
      await ref.read(setReminderCompletedUseCaseProvider)(reminderId: reminderId, completed: completed);
      final updated = reminder?.copyWith(completed: completed);
      state = state.copyWith(
        status: ReminderStatus.success,
        reminders: updated == null ? state.reminders : state.reminders.replacingById(updated),
        clearErrorMessage: true,
      );
      if (updated != null) {
        if (completed) {
          await _cancelNotification(reminderId);
        } else {
          await _updateNotification(updated);
        }
      }
    } catch (error) {
      state = state.copyWith(status: ReminderStatus.error, errorMessage: _messageFor(error));
    }
  }

  /// Cancels the local notification(s) for every reminder currently linked
  /// to [documentId]. Called by Smart Vault right before it deletes a
  /// document, whose `ON DELETE CASCADE` already removes the matching
  /// `reminders` row(s) at the database level -- no duplicate deletion
  /// happens here. This only cleans up the one thing cascade can't reach:
  /// an already-scheduled local notification, which lives entirely outside
  /// Supabase and would otherwise still fire for a document that no longer
  /// exists.
  Future<void> cancelNotificationsForDocument(String documentId) async {
    final reminders = state.reminders.forDocument(documentId);
    for (final reminder in reminders) {
      await _cancelNotification(reminder.id);
    }
  }

  /// Covers all four error categories this phase is scoped to: a
  /// [ReminderException] already carries a friendly message translated
  /// from a Postgrest/network/auth failure (`ReminderRepositoryImpl`'s
  /// job); validation errors never reach this method at all, since they're
  /// caught and turned into `state.errorMessage` before any usecase runs.
  /// Anything else falls back to the same generic message the rest of the
  /// app uses.
  String _messageFor(Object error) {
    if (error is ReminderException) return error.message;
    return AppStrings.genericErrorMessage;
  }

  // ---- Notification synchronization ----
  //
  // Every method below only ever calls `NotificationService` -- never
  // `flutter_local_notifications`/`timezone` directly, and never
  // reimplements *whether* a reminder should be scheduled (that rule lives
  // in `LocalNotificationService._isSchedulable`, not here). A failure here
  // is logged, never surfaced as a controller error: the Supabase write
  // already succeeded, and a missed local notification is recoverable (the
  // next app launch's restore-on-startup bootstrap reconciles it), unlike
  // an error state that would make an otherwise-successful save look
  // failed.

  Future<void> _scheduleNotification(Reminder reminder) =>
      _runNotificationSync(() => ref.read(notificationServiceProvider).scheduleReminder(reminder), 'schedule');

  Future<void> _updateNotification(Reminder reminder) =>
      _runNotificationSync(() => ref.read(notificationServiceProvider).updateReminder(reminder), 'update');

  Future<void> _cancelNotification(String reminderId) =>
      _runNotificationSync(() => ref.read(notificationServiceProvider).cancelReminder(reminderId), 'cancel');

  Future<void> _runNotificationSync(Future<void> Function() action, String verb) async {
    try {
      await action();
    } catch (error) {
      debugPrint('[NOTIFICATIONS] Failed to $verb notification: $error');
    }
  }
}

final reminderControllerProvider = NotifierProvider<ReminderController, ReminderState>(ReminderController.new);
