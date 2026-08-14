import '../repositories/reminder_repository.dart';

class DeleteReminderUseCase {
  const DeleteReminderUseCase(this._repository);
  final ReminderRepository _repository;

  Future<void> call(String reminderId) => _repository.deleteReminder(reminderId);
}
