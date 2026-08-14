import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({required String email, required String password}) {
    // TEMPORARY DEV LOGGING -- remove once the registration issue is
    // diagnosed. Uses plain `print`, not `debugPrint`, so this domain-layer
    // file doesn't gain a Flutter dependency even temporarily.
    // ignore: avoid_print
    print('[STEP 3] RegisterUseCase.call -- calling AuthRepository.register()');
    // ignore: avoid_print
    print('[STEP 3] email: $email');
    return _repository.register(email: email, password: password);
  }
}
