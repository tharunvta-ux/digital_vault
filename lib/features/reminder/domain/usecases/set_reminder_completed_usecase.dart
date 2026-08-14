import '../repositories/reminder_repository.dart';

class SetReminderCompletedUseCase {
  const SetReminderCompletedUseCase(this._repository);
  final ReminderRepository _repository;

  Future<void> call({required String reminderId, required bool completed}) {
    return _repository.setReminderCompleted(reminderId: reminderId, completed: completed);
  }
}
