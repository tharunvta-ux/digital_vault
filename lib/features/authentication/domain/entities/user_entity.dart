/// Domain representation of an authenticated user.
///
/// Deliberately minimal — only what the app actually needs post sign-in.
/// No `displayName`: Module 2 never stores the Register screen's Full Name
/// field anywhere, including here.
class UserEntity {
  const UserEntity({required this.uid, required this.email});

  final String uid;
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);

  @override
  String toString() => 'UserEntity(uid: $uid, email: $email)';
}
