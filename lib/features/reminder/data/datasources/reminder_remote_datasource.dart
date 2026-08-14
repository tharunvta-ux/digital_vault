/// Thin wrapper contract over the Supabase `reminders` table. Deals only
/// in raw rows (`Map<String, dynamic>`, as returned by PostgREST) and
/// UIDs; mapping to/from the domain entity happens one layer up, in the
/// repository (via `ReminderModel`), exactly like the Smart Vault
/// feature's datasource stays ignorant of `Reminder`.
///
/// Every method is scoped by an explicit [uid] parameter rather than
/// resolving "who's logged in" itself -- that's the repository's job; this
/// class just does whatever per-user filter it's told. Row Level Security
/// enforces the same scoping server-side, so this is defense in depth, not
/// the only thing standing between a user and someone else's reminders.
abstract class ReminderRemoteDataSource {
  /// Inserts a new reminder and returns the full inserted row, including
  /// the server-generated `id`, `created_at`, and `updated_at`. Unlike
  /// `vault_documents`, nothing needs the ID before the row exists, so it's
  /// left to Postgres' `default gen_random_uuid()` rather than minted
  /// client-side.
  Future<Map<String, dynamic>> createReminder({
    required String uid,
    required Map<String, dynamic> data,
  });

  /// Live, soonest-due-first list of every reminder for [uid].
  Stream<List<Map<String, dynamic>>> watchReminders(String uid);

  /// One-shot, soonest-due-first list of every reminder for [uid] -- a
  /// plain PostgREST `select`, no Realtime subscription. For callers (like
  /// the notification-restore bootstrap) that need the current list once
  /// and are done; unlike [watchReminders], this never opens a Realtime
  /// channel just to read a value and discard the subscription.
  Future<List<Map<String, dynamic>>> fetchReminders(String uid);

  /// A single reminder, or `null` if it doesn't exist under [uid].
  Future<Map<String, dynamic>?> getReminder({
    required String uid,
    required String reminderId,
  });

  /// Updates [reminderId] and returns the full updated row (so the
  /// trigger-maintained `updated_at` comes back without a second read).
  Future<Map<String, dynamic>> updateReminder({
    required String uid,
    required String reminderId,
    required Map<String, dynamic> data,
  });

  Future<void> deleteReminder({required String uid, required String reminderId});
}
