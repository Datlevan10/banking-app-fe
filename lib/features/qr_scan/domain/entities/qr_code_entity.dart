import 'package:equatable/equatable.dart';

/// A parsed bank-transfer QR code (e.g. VietQR / EMVCo payload).
///
/// Pure domain entity: no Flutter, no parsing logic — the data layer produces
/// it, the presentation layer consumes it.
class QrCodeEntity extends Equatable {
  const QrCodeEntity({
    required this.bankName,
    required this.accountNumber,
    required this.recipientName,
    this.amount,
    this.remarks = '',
  });

  final String bankName;
  final String accountNumber;
  final String recipientName;

  /// Optional amount encoded in the QR (null when absent).
  final double? amount;
  final String remarks;

  @override
  List<Object?> get props =>
      <Object?>[bankName, accountNumber, recipientName, amount, remarks];
}
