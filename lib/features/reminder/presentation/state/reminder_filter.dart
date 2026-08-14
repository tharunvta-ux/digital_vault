/// Which slice of `ReminderState.reminders` the Reminder List Screen shows.
///
/// [all]/[upcoming]/[overdue]/[completed] map 1:1 onto `ReminderState`'s own
/// computed collections -- this enum never reimplements that
/// classification, it only names it for a filter chip. [notificationsEnabled]
/// /[notificationsDisabled] are the two options `ReminderState` has no
/// reason to expose itself, since they're a stored flag, not a business
/// classification.
enum ReminderFilter {
  all,
  upcoming,
  overdue,
  completed,
  notificationsEnabled,
  notificationsDisabled;

  String get label {
    switch (this) {
      case ReminderFilter.all:
        return 'All';
      case ReminderFilter.upcoming:
        return 'Upcoming';
      case ReminderFilter.overdue:
        return 'Overdue';
      case ReminderFilter.completed:
        return 'Completed';
      case ReminderFilter.notificationsEnabled:
        return 'Notifications On';
      case ReminderFilter.notificationsDisabled:
        return 'Notifications Off';
    }
  }
}
