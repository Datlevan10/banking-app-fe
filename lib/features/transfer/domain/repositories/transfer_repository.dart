import '../entities/beneficiary.dart';
import '../entities/transfer_entity.dart';

/// Contract for the transfer feature's data needs.
///
/// [submitTransfer] returns the settled [TransferEntity] on success and throws
/// a `TransferFailure` otherwise — a uniform result shape the BLoC can handle
/// without knowing anything about the underlying transport.
abstract interface class TransferRepository {
  /// The user's saved beneficiaries (quick-select list).
  Future<List<Beneficiary>> getBeneficiaries();

  /// The source account's currently available balance (for validation).
  Future<double> getAvailableBalance();

  /// Execute a transfer and return its receipt.
  Future<TransferEntity> submitTransfer({
    required Beneficiary beneficiary,
    required double amount,
    required String remarks,
  });
}
