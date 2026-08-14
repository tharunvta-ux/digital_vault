import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

class WatchRemindersUseCase {
  const WatchRemindersUseCase(this._repository);
  final ReminderRepository _repository;

  Stream<List<Reminder>> call() => _repository.watchReminders();
}
