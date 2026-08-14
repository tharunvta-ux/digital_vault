import '../repositories/auth_repository.dart';

class WatchPasswordRecoveryUseCase {
  const WatchPasswordRecoveryUseCase(this._repository);

  final AuthRepository _repository;

  Stream<bool> call() {
    return _repository.passwordRecoveryEvents();
  }
}
