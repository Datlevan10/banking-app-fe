import 'package:equatable/equatable.dart';

/// The newly created account returned when registration completes.
class RegisteredAccount extends Equatable {
  const RegisteredAccount({
    required this.accountNumber,
    required this.username,
    required this.createdAt,
  });

  final String accountNumber;
  final String username;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[accountNumber, username, createdAt];
}
