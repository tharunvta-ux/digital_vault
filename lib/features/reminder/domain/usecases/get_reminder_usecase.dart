import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

class GetReminderUseCase {
  const GetReminderUseCase(this._repository);
  final ReminderRepository _repository;

  Future<Reminder?> call(String reminderId) => _repository.getReminderById(reminderId);
}
