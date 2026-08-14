/// How the Reminder List Screen orders reminders within each section.
enum ReminderSortOption {
  nearestDate,
  latestDate,
  alphabetical,
  recentlyCreated;

  String get label {
    switch (this) {
      case ReminderSortOption.nearestDate:
        return 'Nearest Date';
      case ReminderSortOption.latestDate:
        return 'Latest Date';
      case ReminderSortOption.alphabetical:
        return 'Alphabetical';
      case ReminderSortOption.recentlyCreated:
        return 'Recently Created';
    }
  }
}
