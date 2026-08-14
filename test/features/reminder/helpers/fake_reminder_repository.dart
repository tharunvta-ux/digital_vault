import 'dart:async';

import 'package:digital_vault/features/reminder/domain/entities/reminder.dart';
import 'package:digital_vault/features/reminder/domain/entities/repeat_type.dart';
import 'package:digital_vault/features/reminder/domain/repositories/reminder_repository.dart';

/// Hand-written test double, matching `FakeAuthRepository`'s convention --
/// no mocking library needed since [ReminderRepository] only ever traffics
/// in our own domain types. Minimal: only what widget tests that merely
/// need a controllable live list (e.g. the Dashboard's reminder overview)
/// actually exercise -- write methods aren't implemented since nothing
/// using this fake today calls them.
class FakeReminderRepository implements ReminderRepository {
  FakeReminderRepository({List<Reminder> initialReminders = const []}) : _reminders = List.of(initialReminders);

  final List<Reminder> _reminders;
  final StreamController<List<Reminder>> _controller = StreamController<List<Reminder>>.broadcast();

  @override
  Stream<List<Reminder>> watchReminders() async* {
    // Mirrors real Realtime behavior: a new subscriber immediately gets the
    // current list, then subsequent changes.
    yield List.of(_reminders);
    yield* _controller.stream;
  }

  @override
  Future<List<Reminder>> fetchReminders() async => List.of(_reminders);

  @override
  Future<Reminder?> getReminderById(String reminderId) async {
    for (final reminder in _reminders) {
      if (reminder.id == reminderId) return reminder;
    }
    return null;
  }

  @override
  Future<Reminder> createReminder({
    required String documentId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) => throw UnimplementedError('Not needed by the tests using this fake yet.');

  @override
  Future<Reminder> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) => throw UnimplementedError('Not needed by the tests using this fake yet.');

  @override
  Future<void> setReminderCompleted({required String reminderId, required bool completed}) =>
      throw UnimplementedError('Not needed by the tests using this fake yet.');

  @override
  Future<void> deleteReminder(String reminderId) =>
      throw UnimplementedError('Not needed by the tests using this fake yet.');

  void dispose() => _controller.close();
}
