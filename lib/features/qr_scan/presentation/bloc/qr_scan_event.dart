part of 'qr_scan_bloc.dart';

/// Events for the QR scanner screen.
sealed class QrScanEvent extends Equatable {
  const QrScanEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Begin the scan: check permission, capture and parse.
final class QrScanStarted extends QrScanEvent {
  const QrScanStarted();
}

/// Toggle the camera torch (flashlight).
final class QrTorchToggled extends QrScanEvent {
  const QrTorchToggled();
}

/// Retry after a failure.
final class QrScanRetryRequested extends QrScanEvent {
  const QrScanRetryRequested();
}
