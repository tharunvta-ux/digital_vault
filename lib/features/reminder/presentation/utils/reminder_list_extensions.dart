import '../../domain/entities/reminder.dart';

/// Small, pure list operations over an already-loaded reminder list, e.g.
/// `ReminderState.reminders`. Used by [ReminderController] to keep that
/// list correct immediately after a write -- the `reminders` table has no
/// Realtime publication enabled (a deliberate Phase 1 decision), so nothing
/// ever pushes a create/update/delete back to an open subscription; each
/// write has to patch the in-memory list itself rather than waiting for an
/// update that will never arrive.
extension ReminderListLookup on List<Reminder> {
  Reminder? findById(String id) {
    for (final reminder in this) {
      if (reminder.id == id) return reminder;
    }
    return null;
  }

  /// Returns a copy with [reminder] appended.
  List<Reminder> appending(Reminder reminder) => [...this, reminder];

  /// Returns a copy with whichever existing reminder shares [reminder]'s ID
  /// replaced by it. If none match (shouldn't happen for an update that
  /// just round-tripped through Supabase), [reminder] is left out rather
  /// than silently appended -- an update can't materialize a reminder that
  /// wasn't already known.
  List<Reminder> replacingById(Reminder reminder) =>
      [for (final existing in this) if (existing.id == reminder.id) reminder else existing];

  /// Returns a copy with the reminder matching [id] removed.
  List<Reminder> removingById(String id) => where((reminder) => reminder.id != id).toList();
}
