import '../entities/reminder.dart';
import '../entities/repeat_type.dart';
import '../repositories/reminder_repository.dart';

class UpdateReminderUseCase {
  const UpdateReminderUseCase(this._repository);
  final ReminderRepository _repository;

  Future<Reminder> call({
    required String reminderId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) {
    return _repository.updateReminder(
      reminderId: reminderId,
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      repeatType: repeatType,
      notificationEnabled: notificationEnabled,
    );
  }
}
