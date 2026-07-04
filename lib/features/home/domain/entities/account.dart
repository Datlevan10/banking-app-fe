import 'package:equatable/equatable.dart';

/// A bank account whose balance is shown on the dashboard [BalanceCard].
class Account extends Equatable {
  const Account({
    required this.id,
    required this.holderName,
    required this.maskedNumber,
    required this.balance,
    this.currencyCode = 'USD',
  });

  final String id;
  final String holderName;

  /// Only the last digits are ever exposed, e.g. `•••• 4921`.
  final String maskedNumber;
  final double balance;
  final String currencyCode;

  @override
  List<Object?> get props => <Object?>[
    id,
    holderName,
    maskedNumber,
    balance,
    currencyCode,
  ];
}
