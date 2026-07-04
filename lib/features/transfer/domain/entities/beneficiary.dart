import 'package:equatable/equatable.dart';

/// A saved payee the user can transfer money to.
///
/// Pure domain entity — no Flutter, no JSON. [initials] is derived here so the
/// UI never re-implements the same string logic.
class Beneficiary extends Equatable {
  const Beneficiary({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
  });

  final String id;
  final String name;

  /// Masked account number, e.g. `•••• 8842`.
  final String accountNumber;
  final String bankName;

  /// Up to two uppercase initials for avatar display, e.g. `John Doe` -> `JD`.
  String get initials {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => <Object?>[id, name, accountNumber, bankName];
}
