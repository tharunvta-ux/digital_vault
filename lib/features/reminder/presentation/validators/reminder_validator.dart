import '../../domain/entities/repeat_type.dart';

/// Centralized validation for reminder input, run by `ReminderController`
/// before any create/update call ever reaches a usecase. Deliberately
/// distinct from `core/utils/validators.dart`'s per-field `FormField`
/// validators (which return an error for one field, called from inside a
/// widget's `validator:` callback) -- this validates a whole reminder
/// request as one unit, from the business-logic layer, so no future UI
/// screen needs its own validation logic at all.
class ReminderValidator {
  const ReminderValidator._();

  static const int maxTitleLength = 200;

  /// Validates every field a create/update call needs, in order, returning
  /// the first problem found (or `null` if everything is valid). A single
  /// error at a time, matching `core/utils/validators.dart`'s convention,
  /// rather than a list -- simpler for a caller to display, and title/date
  /// problems are typically fixed one at a time anyway.
  static String? validate({
    required String title,
    required DateTime scheduledAt,
    required RepeatType repeatType,
  }) {
    return validateTitle(title) ??
        validateDate(scheduledAt) ??
        validateTime(scheduledAt) ??
        validateRepeatType(repeatType);
  }

  static String? validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Title is required.';
    if (trimmed.length > maxTitleLength) {
      return 'Title must be $maxTitleLength characters or fewer.';
    }
    return null;
  }

  /// The date portion of [scheduledAt] must not be in the past. Compares
  /// calendar dates, not exact instants -- "today" is always a valid
  /// reminder date regardless of what time it currently is.
  static String? validateDate(DateTime scheduledAt) {
    final today = _dateOnly(DateTime.now());
    final scheduledDate = _dateOnly(scheduledAt);
    if (scheduledDate.isBefore(today)) {
      return 'Reminder date cannot be in the past.';
    }
    return null;
  }

  /// If [scheduledAt] falls on today's date, its time must not already
  /// have passed. A future date needs no time check -- any time of day on
  /// a future date is valid.
  static String? validateTime(DateTime scheduledAt) {
    final now = DateTime.now();
    final isToday = _dateOnly(scheduledAt) == _dateOnly(now);
    if (isToday && scheduledAt.isBefore(now)) {
      return 'Reminder time cannot be in the past.';
    }
    return null;
  }

  /// [repeatType] is a closed Dart enum -- every value the type system
  /// allows is already a valid one, so this can never actually fail from
  /// validated Dart code. Kept as an explicit check (rather than omitted)
  /// so "repeat type" stays a visible, centralized validation step, not an
  /// assumption baked silently into the type system.
  static String? validateRepeatType(RepeatType repeatType) => null;

  static DateTime _dateOnly(DateTime dateTime) => DateTime(dateTime.year, dateTime.month, dateTime.day);
}
