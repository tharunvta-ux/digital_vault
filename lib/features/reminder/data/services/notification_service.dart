import '../../domain/entities/reminder.dart';

/// Contract for scheduling local device notifications for reminders.
///
/// Deals only in domain [Reminder]s -- nothing in this file, or anything
/// that depends only on it, knows `flutter_local_notifications` or
/// `timezone` exist. Deliberately independent of `ReminderRepository`/
/// Supabase too: this service never fetches reminders itself, it only
/// schedules whatever it's given. Callers (the app-startup bootstrap, and
/// eventually the reminder UI) are responsible for deciding *which*
/// reminders to pass it.
abstract class NotificationService {
  /// Prepares the plugin and the timezone database for use. Must complete
  /// before any other method is called. Safe to call more than once.
  Future<void> initialize();

  /// Requests whatever notification permission the current platform
  /// requires (Android 13+'s runtime POST_NOTIFICATIONS, Android 12+'s
  /// exact-alarm access, iOS/macOS's alert/sound/badge permissions).
  /// Returns whether permission was granted. A denial is not an error --
  /// scheduling calls still succeed, they just won't visibly notify.
  Future<bool> requestPermission();

  /// Schedules [reminder]'s notification. A no-op, not an error, if
  /// [reminder] is completed, has notifications disabled, or is a one-time
  /// reminder whose time has already passed -- see the implementation for
  /// why recurring reminders in the past are still schedulable.
  Future<void> scheduleReminder(Reminder reminder);

  /// Replaces whatever notification is currently scheduled for
  /// [reminder]'s ID with one reflecting its current fields. Safe to call
  /// whether or not one was previously scheduled.
  Future<void> updateReminder(Reminder reminder);

  /// Cancels the notification for [reminderId], if one is scheduled. A
  /// no-op, not an error, if it isn't.
  Future<void> cancelReminder(String reminderId);

  /// Cancels every reminder notification this app has scheduled.
  Future<void> cancelAllReminders();

  /// Replaces every currently-scheduled reminder notification with a fresh
  /// set derived from [reminders] -- the source of truth is whatever's
  /// passed in, not whatever was previously scheduled. Reminders that are
  /// completed or have notifications disabled are skipped, same as
  /// [scheduleReminder]. Intended for app startup, to reconcile the
  /// device's scheduled alarms (which don't survive every OS/plugin
  /// lifecycle event) against the current state in Supabase.
  Future<void> restoreScheduledReminders(List<Reminder> reminders);

  /// The notification IDs currently scheduled (not yet delivered).
  Future<List<int>> pendingNotifications();
}
