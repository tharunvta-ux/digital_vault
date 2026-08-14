import '../../domain/entities/reminder.dart';
import '../state/reminder_filter.dart';
import '../state/reminder_sort_option.dart';
import '../state/reminder_state.dart';
import 'reminder_ui_status.dart';

/// The three grouped sections the Reminder List Screen always renders,
/// already filtered, matched against a search query, and sorted -- computed
/// fresh on every build (see [buildReminderListGroups]), never cached, so
/// "upcoming" vs "overdue" always reflects the current wall-clock time.
class ReminderListGroups {
  const ReminderListGroups({
    required this.upcoming,
    required this.overdue,
    required this.completed,
  });

  final List<Reminder> upcoming;
  final List<Reminder> overdue;
  final List<Reminder> completed;

  bool get isEmpty => upcoming.isEmpty && overdue.isEmpty && completed.isEmpty;
}

/// Picks the base list [filter] refers to, straight from `ReminderState`'s
/// own computed collections wherever one matches 1:1 -- never reimplements
/// "what counts as upcoming/overdue/completed." The two notification
/// filters are the only ones not already exposed by `ReminderState`, since
/// they're a stored flag, not a business classification.
List<Reminder> _baseListFor(ReminderState state, ReminderFilter filter) {
  switch (filter) {
    case ReminderFilter.all:
      return state.reminders;
    case ReminderFilter.upcoming:
      return state.upcomingReminders;
    case ReminderFilter.overdue:
      return state.overdueReminders;
    case ReminderFilter.completed:
      return state.completedReminders;
    case ReminderFilter.notificationsEnabled:
      return state.reminders.where((r) => r.notificationEnabled).toList();
    case ReminderFilter.notificationsDisabled:
      return state.reminders.where((r) => !r.notificationEnabled).toList();
  }
}

bool _matchesQuery(Reminder reminder, String query, String? documentTitle) {
  if (query.isEmpty) return true;
  final lowerQuery = query.toLowerCase();
  if (reminder.title.toLowerCase().contains(lowerQuery)) return true;
  final description = reminder.description;
  if (description != null && description.toLowerCase().contains(lowerQuery)) return true;
  if (documentTitle != null && documentTitle.toLowerCase().contains(lowerQuery)) return true;
  return false;
}

List<Reminder> _sorted(List<Reminder> reminders, ReminderSortOption sort) {
  final sorted = [...reminders];
  switch (sort) {
    case ReminderSortOption.nearestDate:
      sorted.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    case ReminderSortOption.latestDate:
      sorted.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    case ReminderSortOption.alphabetical:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case ReminderSortOption.recentlyCreated:
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  return sorted;
}

/// Builds the three sections the list screen renders, given the current
/// [state], the selected [filter], the raw search [query], the chosen
/// [sort], and a `documentId -> title` lookup ([documentTitles], sourced
/// from Smart Vault's existing, unmodified `watchAllDocumentsProvider`)
/// used both for display and for matching the "linked document title" part
/// of a search.
ReminderListGroups buildReminderListGroups({
  required ReminderState state,
  required ReminderFilter filter,
  required String query,
  required ReminderSortOption sort,
  required Map<String, String> documentTitles,
}) {
  final base = _baseListFor(state, filter);
  final matched = base.where((r) => _matchesQuery(r, query, documentTitles[r.documentId])).toList();

  final upcoming = <Reminder>[];
  final overdue = <Reminder>[];
  final completed = <Reminder>[];
  for (final reminder in matched) {
    final status = ReminderUiStatus.of(reminder);
    if (status == ReminderUiStatus.upcoming) {
      upcoming.add(reminder);
    } else if (status == ReminderUiStatus.overdue) {
      overdue.add(reminder);
    } else {
      completed.add(reminder);
    }
  }

  return ReminderListGroups(
    upcoming: _sorted(upcoming, sort),
    overdue: _sorted(overdue, sort),
    completed: _sorted(completed, sort),
  );
}
