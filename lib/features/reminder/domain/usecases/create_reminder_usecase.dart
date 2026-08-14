import '../entities/reminder.dart';
import '../entities/repeat_type.dart';
import '../repositories/reminder_repository.dart';

class CreateReminderUseCase {
  const CreateReminderUseCase(this._repository);
  final ReminderRepository _repository;

  Future<Reminder> call({
    required String documentId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required RepeatType repeatType,
    required bool notificationEnabled,
  }) {
    return _repository.createReminder(
      documentId: documentId,
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      repeatType: repeatType,
      notificationEnabled: notificationEnabled,
    );
  }
}
