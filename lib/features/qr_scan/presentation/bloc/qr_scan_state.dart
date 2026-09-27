part of 'qr_scan_bloc.dart';

/// Lifecycle of the scan.
enum QrScanStatus { scanning, processing, success, failure }

/// Immutable scanner state.
final class QrScanState extends Equatable {
  const QrScanState({
    this.status = QrScanStatus.scanning,
    this.torchOn = false,
    this.result,
    this.errorMessage,
  });

  final QrScanStatus status;
  final bool torchOn;

  /// The parsed code, available on [QrScanStatus.success].
  final QrCodeEntity? result;
  final String? errorMessage;

  QrScanState copyWith({
    QrScanStatus? status,
    bool? torchOn,
    QrCodeEntity? result,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QrScanState(
      status: status ?? this.status,
      torchOn: torchOn ?? this.torchOn,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, torchOn, result, errorMessage];
}
