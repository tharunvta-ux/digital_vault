import 'package:supabase_flutter/supabase_flutter.dart';

import 'reminder_remote_datasource.dart';

/// Supabase/PostgREST-backed implementation of [ReminderRemoteDataSource].
/// Deals only in raw rows and PostgREST filters; mapping to/from the
/// domain entity still happens one layer up, in the repository.
class SupabaseReminderRemoteDataSource implements ReminderRemoteDataSource {
  const SupabaseReminderRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _table = 'reminders';

  @override
  Future<Map<String, dynamic>> createReminder({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return _client.from(_table).insert(data).select().single();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchReminders(String uid) {
    // `.stream()` only accepts a single `.order()` column (verified against
    // supabase_flutter's source during the Smart Vault migration -- the
    // same limitation applies here), so this orders by date only.
    // `reminders_owner_date_time_idx` still speeds up the initial fetch;
    // the exact date+time chronological order is finished client-side by
    // the repository, which has a single combined `scheduledAt` to sort by.
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('owner_uid', uid)
        .order('reminder_date', ascending: true);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchReminders(String uid) {
    return _client.from(_table).select().eq('owner_uid', uid).order('reminder_date', ascending: true);
  }

  @override
  Future<Map<String, dynamic>?> getReminder({
    required String uid,
    required String reminderId,
  }) {
    return _client.from(_table).select().eq('id', reminderId).eq('owner_uid', uid).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> updateReminder({
    required String uid,
    required String reminderId,
    required Map<String, dynamic> data,
  }) {
    return _client
        .from(_table)
        .update(data)
        .eq('id', reminderId)
        .eq('owner_uid', uid)
        .select()
        .single();
  }

  @override
  Future<void> deleteReminder({required String uid, required String reminderId}) async {
    await _client.from(_table).delete().eq('id', reminderId).eq('owner_uid', uid);
  }
}
