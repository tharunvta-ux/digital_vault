import '../../domain/entities/reminder.dart';

/// Derives "the reminder(s) for this document" purely from an
/// already-loaded reminder list (e.g. `ReminderState.reminders`) -- no
/// Supabase query of its own. Used by Smart Vault's Document Details
/// section, its document-card indicator/menu, the Dashboard's overview,
/// and notification cleanup on document delete, so every one of those
/// reuses the same live, cached list `ReminderController` already keeps in
/// sync via Realtime.
extension RemindersByDocument on List<Reminder> {
  List<Reminder> forDocument(String documentId) => where((r) => r.documentId == documentId).toList();

  /// The single reminder to show wherever the UI expects "the" reminder for
  /// a document (Document Details, the card indicator). Nothing in this
  /// feature prevents creating more than one reminder for the same
  /// document, so when that happens, this deterministically picks the one
  /// with the nearest `scheduledAt` -- matching the "nearest reminders"
  /// framing used elsewhere (e.g. the Dashboard's overview).
  Reminder? primaryForDocument(String documentId) {
    final matches = forDocument(documentId);
    if (matches.isEmpty) return null;
    return matches.reduce((a, b) => a.scheduledAt.isBefore(b.scheduledAt) ? a : b);
  }
}
