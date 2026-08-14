import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_type.dart';
import '../../domain/reminder_exception.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_remote_datasource.dart';
import '../models/reminder_model.dart';

/// The single place that touches [supabase.PostgrestException] and
/// resolves "who is the current user" -- every other layer only ever sees
/// [ReminderException] with an already-friendly message, and repository
/// callers never pass a UID. Mirrors `VaultRepositoryImpl` exactly.
class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl(this._remoteDataSource, this._supabaseClient);

  final ReminderRemoteDataSource _remoteDataSource;
  final supabase.SupabaseClient _supabaseClient;

  String get _uid {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const ReminderException('You must be signed in to do this.');
    }
    return user.id;
  }

  @override
  Future<Reminder> createReminder({
    required String documentId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) {
    return _run(() async {
      final uid = _uid;
      final data = ReminderModel.buildInsertMap(
        ownerUid: uid,
        documentId: documentId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        repeatType: repeatType,
        notificationEnabled: notificationEnabled,
      );
      final row = await _remoteDataSource.createReminder(uid: uid, data: data);
      return ReminderModel.fromMap(row);
    });
  }

  @override
  Future<Reminder> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) {
    return _run(() async {
      final uid = _uid;
      final data = ReminderModel.buildUpdateMap(
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        repeatType: repeatType,
        notificationEnabled: notificationEnabled,
      );
      final row = await _remoteDataSource.updateReminder(uid: uid, reminderId: reminderId, data: data);
      return ReminderModel.fromMap(row);
    });
  }

  @override
  Future<void> setReminderCompleted({required String reminderId, required bool completed}) {
    return _run(() async {
      final uid = _uid;
      await _remoteDataSource.updateReminder(
        uid: uid,
        reminderId: reminderId,
        data: {'completed': completed},
      );
    });
  }

  @override
  Future<void> deleteReminder(String reminderId) {
    return _run(() async {
      await _remoteDataSource.deleteReminder(uid: _uid, reminderId: reminderId);
    });
  }

  @override
  Future<Reminder?> getReminderById(String reminderId) {
    return _run(() async {
      final row = await _remoteDataSource.getReminder(uid: _uid, reminderId: reminderId);
      if (row == null) return null;
      return ReminderModel.fromMap(row);
    });
  }

  @override
  Stream<List<Reminder>> watchReminders() {
    return _remoteDataSource.watchReminders(_uid).map((rows) {
      final reminders = rows.map(ReminderModel.fromMap).toList()
        // The stream can only sort by one column server-side (date); this
        // finishes the exact date+time chronological order using the
        // domain entity's single combined `scheduledAt`.
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return reminders;
    }).handleError((Object error) {
      if (error is ReminderException) throw error;
      if (error is supabase.RealtimeSubscribeException) {
        // Not fatal -- same reasoning as VaultRepositoryImpl: the live-push
        // side failing to attach doesn't close the underlying stream, and
        // the one-shot fetch that already ran keeps the list correct.
        return;
      }
      if (error is supabase.PostgrestException) {
        throw ReminderException(mapReminderPostgrestError(error.code));
      }
      throw const ReminderException(AppStrings.genericErrorMessage);
    });
  }

  @override
  Future<List<Reminder>> fetchReminders() {
    return _run(() async {
      final rows = await _remoteDataSource.fetchReminders(_uid);
      return rows.map(ReminderModel.fromMap).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ReminderException {
      rethrow;
    } on supabase.PostgrestException catch (e) {
      throw ReminderException(mapReminderPostgrestError(e.code));
    } catch (_) {
      throw const ReminderException(AppStrings.genericErrorMessage);
    }
  }
}

/// Pure mapping from a Postgres/PostgREST error code to a user-friendly
/// message. Mirrors `mapVaultPostgrestError` exactly.
String mapReminderPostgrestError(String? code) {
  switch (code) {
    case '42501':
      return 'You do not have permission to do that.';
    case '23503':
      // foreign_key_violation -- e.g. documentId pointing at a document
      // that doesn't exist (or isn't this user's).
      return 'The selected document could not be found.';
    case 'PGRST116':
      return 'The reminder could not be found.';
    default:
      return AppStrings.genericErrorMessage;
  }
}
