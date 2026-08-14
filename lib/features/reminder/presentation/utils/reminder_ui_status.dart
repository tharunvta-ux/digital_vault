import '../../domain/entities/reminder.dart';

/// Which of the three display groups a single reminder currently falls
/// into. Mirrors `ReminderState`'s own `upcomingReminders`/`overdueReminders`
/// /`completedReminders` predicates exactly (same rules, same "evaluated
/// against now, not cached" semantics) -- this just exposes that
/// classification for one reminder at a time, for widgets that render a
/// single card (status chip, section grouping) rather than a whole list.
enum ReminderUiStatus {
  upcoming,
  overdue,
  completed;

  static ReminderUiStatus of(Reminder reminder) {
    if (reminder.completed) return ReminderUiStatus.completed;
    return reminder.scheduledAt.isAfter(DateTime.now())
        ? ReminderUiStatus.upcoming
        : ReminderUiStatus.overdue;
  }

  String get label {
    switch (this) {
      case ReminderUiStatus.upcoming:
        return 'Upcoming';
      case ReminderUiStatus.overdue:
        return 'Overdue';
      case ReminderUiStatus.completed:
        return 'Completed';
    }
  }
}
