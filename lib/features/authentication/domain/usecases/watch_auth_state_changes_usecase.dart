import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class WatchAuthStateChangesUseCase {
  const WatchAuthStateChangesUseCase(this._repository);

  final AuthRepository _repository;

  Stream<UserEntity?> call() {
    return _repository.authStateChanges();
  }
}
