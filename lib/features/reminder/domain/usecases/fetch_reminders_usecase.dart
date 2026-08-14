import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

class FetchRemindersUseCase {
  const FetchRemindersUseCase(this._repository);
  final ReminderRepository _repository;

  Future<List<Reminder>> call() => _repository.fetchReminders();
}
