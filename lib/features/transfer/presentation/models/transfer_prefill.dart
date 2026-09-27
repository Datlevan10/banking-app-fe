import 'package:equatable/equatable.dart';

/// Data used to pre-populate the transfer flow (e.g. from a scanned QR code).
///
/// Deliberately built from primitives so callers (like the QR feature) don't
/// need to depend on the transfer domain's `Beneficiary` entity — the
/// [TransferBloc] constructs that internally.
class TransferPrefill extends Equatable {
  const TransferPrefill({
    required this.recipientName,
    required this.accountNumber,
    required this.bankName,
    this.amount,
    this.remarks = '',
  });

  final String recipientName;
  final String accountNumber;
  final String bankName;

  /// Optional pre-filled amount; null when the QR carries no amount.
  final double? amount;
  final String remarks;

  @override
  List<Object?> get props =>
      <Object?>[recipientName, accountNumber, bankName, amount, remarks];
}
