import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/user_entity.dart';

/// Maps a backend SDK's user type to the domain [UserEntity].
class UserModel extends UserEntity {
  /// Supabase's `id` (a uuid string) fills the same role Firebase's `uid`
  /// did -- both are just "the authenticated user's unique identifier."
  UserModel.fromSupabaseUser(supabase.User user)
      : super(uid: user.id, email: user.email ?? '');
}
