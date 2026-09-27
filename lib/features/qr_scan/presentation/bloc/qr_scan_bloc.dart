import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/qr_code_entity.dart';
import '../../domain/failures/qr_scan_failure.dart';
import '../../domain/repositories/qr_scan_repository.dart';

part 'qr_scan_event.dart';
part 'qr_scan_state.dart';

/// Owns the QR scan flow: permission → capture → parse. The UI dispatches
/// events and renders states; on success it reads [QrScanState.result] and
/// routes to the transfer screen.
class QrScanBloc extends Bloc<QrScanEvent, QrScanState> {
  QrScanBloc({required this._repository}) : super(const QrScanState()) {
    on<QrScanStarted>(_onStarted);
    on<QrScanRetryRequested>(_onRetry);
    on<QrTorchToggled>(_onTorchToggled);
  }

  final QrScanRepository _repository;

  Future<void> _onStarted(
    QrScanStarted event,
    Emitter<QrScanState> emit,
  ) =>
      _runScan(emit);

  Future<void> _onRetry(
    QrScanRetryRequested event,
    Emitter<QrScanState> emit,
  ) =>
      _runScan(emit);

  void _onTorchToggled(QrTorchToggled event, Emitter<QrScanState> emit) {
    emit(state.copyWith(torchOn: !state.torchOn));
  }

  Future<void> _runScan(Emitter<QrScanState> emit) async {
    emit(state.copyWith(status: QrScanStatus.scanning, clearError: true));
    try {
      final bool granted = await _repository.requestCameraPermission();
      if (!granted) {
        emit(state.copyWith(
          status: QrScanStatus.failure,
          errorMessage: QrScanFailure.permissionDenied.message,
        ));
        return;
      }

      final String raw = await _repository.captureQr();
      emit(state.copyWith(status: QrScanStatus.processing));

      final QrCodeEntity result = _repository.parsePayload(raw);
      emit(state.copyWith(status: QrScanStatus.success, result: result));
    } on QrScanFailure catch (failure) {
      emit(state.copyWith(
        status: QrScanStatus.failure,
        errorMessage: failure.message,
      ));
    }
  }
}
