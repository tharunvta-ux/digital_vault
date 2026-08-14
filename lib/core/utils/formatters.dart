/// Generic, feature-agnostic formatting helpers.
class Formatters {
  const Formatters._();

  /// Formats a byte count as a human-readable size, e.g. `1536` -> `1.5 KB`.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB'];
    var value = bytes / 1024;
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Formats a [DateTime] as a simple, locale-agnostic date, e.g.
  /// `Jan 5, 2026`. No `intl` dependency needed for this small a need.
  static String date(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats a [DateTime]'s time-of-day in 12-hour clock form, e.g.
  /// `08:05` -> `8:05 AM`. No `intl` dependency, matching [date].
  static String time(DateTime time) {
    final hour24 = time.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }
}
