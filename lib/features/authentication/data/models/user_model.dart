import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/user_entity.dart';

/// Maps Firebase's [firebase_auth.User] to the domain [UserEntity].
///
/// Purely an in-memory mapper — no `toJson`/persistence, since this module
/// never writes a Firestore user document.
class UserModel extends UserEntity {
  UserModel.fromFirebaseUser(firebase_auth.User user)
      : super(uid: user.uid, email: user.email ?? '');
}
