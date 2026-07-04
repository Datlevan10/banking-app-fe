import 'package:equatable/equatable.dart';

/// The authenticated user returned by a successful sign-in.
///
/// Pure domain entity — no tokens/JSON here; the data layer maps credentials
/// and session tokens into this stable shape.
class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => <Object?>[id, name];
}
