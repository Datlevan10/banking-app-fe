import '../entities/qr_code_entity.dart';

/// Contract for the QR scan flow.
///
/// The presentation layer orchestrates: check permission → capture a raw
/// payload from the camera → parse it. Each method throws a `QrScanFailure`
/// on error, keeping the BLoC decoupled from the camera plugin and payload
/// formats.
abstract interface class QrScanRepository {
  /// Request/verify camera permission. Returns whether it was granted.
  Future<bool> requestCameraPermission();

  /// Capture a raw QR payload from the camera stream (mocked).
  Future<String> captureQr();

  /// Parse a raw payload into a structured [QrCodeEntity].
  QrCodeEntity parsePayload(String raw);
}
