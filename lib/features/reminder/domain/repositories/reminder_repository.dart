import '../entities/reminder.dart';
import '../entities/repeat_type.dart';

/// Contract for all Smart Reminder operations. Implemented by the data
/// layer against Supabase PostgreSQL -- nothing in this file, or anything
/// that depends only on it, knows that backend exists.
///
/// Every method operates implicitly on the currently authenticated user --
/// callers never pass a UID, matching `VaultRepository`'s own contract.
abstract class ReminderRepository {
  /// Creates a reminder for [documentId] and returns it with its
  /// server-assigned `id`/`createdAt`/`updatedAt` filled in.
  Future<Reminder> createReminder({
    required String documentId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  });

  /// Updates an existing reminder's editable fields, returning the updated
  /// reminder.
  Future<Reminder> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  });

  /// Marks [reminderId] done or not done -- a narrower, single-field update
  /// distinct from [updateReminder]'s full edit, matching how a checkbox
  /// tap is a different user action from opening the edit screen.
  Future<void> setReminderCompleted({required String reminderId, required bool completed});

  Future<void> deleteReminder(String reminderId);

  /// A single reminder by ID, or `null` if it doesn't exist or isn't owned
  /// by the current user.
  Future<Reminder?> getReminderById(String reminderId);

  /// A live view of every reminder owned by the current user. Filtering
  /// into upcoming/overdue/completed views is a presentation-layer concern
  /// (same pattern as Smart Vault's category filter over one live list),
  /// not something this contract exposes as separate methods.
  Stream<List<Reminder>> watchReminders();

  /// A one-shot read of every reminder owned by the current user -- for a
  /// caller that needs the current list once and is done (e.g. the
  /// notification-restore bootstrap at app startup), not a live view.
  Future<List<Reminder>> fetchReminders();
}
