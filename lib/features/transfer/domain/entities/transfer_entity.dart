import 'package:equatable/equatable.dart';

import 'beneficiary.dart';

/// A completed transfer — the source of truth for the success receipt.
///
/// Returned by the repository once a transfer settles, carrying the generated
/// [referenceId] and [timestamp] alongside the transfer details.
class TransferEntity extends Equatable {
  const TransferEntity({
    required this.referenceId,
    required this.beneficiary,
    required this.amount,
    required this.remarks,
    required this.timestamp,
  });

  final String referenceId;
  final Beneficiary beneficiary;
  final double amount;
  final String remarks;
  final DateTime timestamp;

  @override
  List<Object?> get props => <Object?>[
    referenceId,
    beneficiary,
    amount,
    remarks,
    timestamp,
  ];
}
