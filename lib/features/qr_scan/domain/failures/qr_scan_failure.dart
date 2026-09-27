/// Domain-level failure for the QR scan flow.
class QrScanFailure implements Exception {
  const QrScanFailure(this.message);

  /// User-safe message the UI can display directly.
  final String message;

  /// The camera permission was not granted.
  static const QrScanFailure permissionDenied = QrScanFailure(
    'Camera access is required to scan QR codes. Please enable it in Settings.',
  );

  /// The scanned data is not a recognised bank-transfer QR code.
  static const QrScanFailure invalidFormat = QrScanFailure(
    'This QR code is not a valid bank transfer code.',
  );

  /// The scan could not be completed (camera error, timeout, …).
  static const QrScanFailure scanFailed = QrScanFailure(
    'We could not read the QR code. Please try again.',
  );

  @override
  String toString() => 'QrScanFailure: $message';
}
