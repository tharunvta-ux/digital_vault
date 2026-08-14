import '../recovery_failure_reason.dart';
import '../repositories/auth_repository.dart';

class WatchRecoveryFailureUseCase {
  const WatchRecoveryFailureUseCase(this._repository);

  final AuthRepository _repository;

  Stream<RecoveryFailureReason> call() {
    return _repository.recoveryFailureEvents();
  }
}
