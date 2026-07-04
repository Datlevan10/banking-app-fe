/// Domain-level failure for the transfer flow.
///
/// Keeps the presentation layer decoupled from network/platform errors: the
/// data layer maps any low-level error into one of these user-safe failures.
class TransferFailure implements Exception {
  const TransferFailure(this.message);

  /// User-safe message the UI can display directly.
  final String message;

  /// A transient network / processing error (retryable).
  static const TransferFailure network = TransferFailure(
    'The transfer could not be completed. Please try again.',
  );

  /// The amount exceeds the available balance.
  static const TransferFailure insufficientBalance = TransferFailure(
    'Amount exceeds your available balance.',
  );

  @override
  String toString() => 'TransferFailure: $message';
}
