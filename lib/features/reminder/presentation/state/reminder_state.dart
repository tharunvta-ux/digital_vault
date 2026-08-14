import '../../domain/entities/reminder.dart';
import 'reminder_status.dart';

/// Presentation-layer state for the entire Smart Reminder feature -- one
/// object covering the live reminder list, whichever single reminder is
/// currently selected (e.g. for a details/edit screen), and the status of
/// whatever operation `ReminderController` last ran.
class ReminderState {
  const ReminderState({
    this.status = ReminderStatus.initial,
    this.reminders = const [],
    this.selectedReminder,
    this.errorMessage,
  });

  final ReminderStatus status;

  /// Every reminder owned by the current user. Seeded from
  /// `watchRemindersProvider`'s initial snapshot, then kept correct by
  /// `ReminderController`'s own write methods patching it directly after
  /// each create/update/delete/complete/reopen -- the `reminders` table has
  /// no Realtime publication enabled, so no push ever arrives here on its
  /// own.
  final List<Reminder> reminders;

  /// The reminder a details/edit screen is currently showing, set by
  /// `ReminderController.getReminderById`. Independent of [reminders] --
  /// selecting one doesn't remove or change anything in the list.
  final Reminder? selectedReminder;

  final String? errorMessage;

  bool get isLoading => status == ReminderStatus.loading;

  bool get hasError => status == ReminderStatus.error;

  // ---- Business logic: computed reminder categories ----
  //
  // Derived on every read from `reminders` and the current wall-clock time,
  // never stored -- so "is this overdue" is always evaluated against *now*,
  // not whatever time the list last loaded at.

  /// Reminders not yet marked done, regardless of when they're due.
  List<Reminder> get activeReminders => reminders.where((r) => !r.completed).toList();

  /// Reminders the user has marked done.
  List<Reminder> get completedReminders => reminders.where((r) => r.completed).toList();

  /// Active reminders whose scheduled time hasn't passed yet.
  List<Reminder> get upcomingReminders =>
      activeReminders.where((r) => r.scheduledAt.isAfter(DateTime.now())).toList();

  /// Active reminders whose scheduled time has already passed.
  List<Reminder> get overdueReminders =>
      activeReminders.where((r) => !r.scheduledAt.isAfter(DateTime.now())).toList();

  /// Returns a copy with the given fields replaced. [selectedReminder] and
  /// [errorMessage] need explicit `clear*` flags rather than relying on
  /// "pass null to clear" -- `copyWith(selectedReminder: null)` would be
  /// indistinguishable from "don't change it" otherwise, since both look
  /// like an omitted argument once inside the method body.
  ReminderState copyWith({
    ReminderStatus? status,
    List<Reminder>? reminders,
    Reminder? selectedReminder,
    String? errorMessage,
    bool clearSelectedReminder = false,
    bool clearErrorMessage = false,
  }) {
    return ReminderState(
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      selectedReminder: clearSelectedReminder ? null : (selectedReminder ?? this.selectedReminder),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
