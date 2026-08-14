/// How often a reminder recurs once its scheduled date/time arrives.
///
/// Adding a new repeat option only ever requires adding another enum value
/// -- [label] is derived from the enum's own name, so no other file needs
/// to change. Matches `reminders.repeat_type`'s CHECK constraint values
/// exactly (`once`, `daily`, `weekly`, `monthly`, `yearly`); if a value is
/// ever added here, the database constraint needs the matching migration.
enum RepeatType {
  once,
  daily,
  weekly,
  monthly,
  yearly;

  /// Human-readable label for display (e.g. `once` -> `Once`).
  String get label => name[0].toUpperCase() + name.substring(1);
}
