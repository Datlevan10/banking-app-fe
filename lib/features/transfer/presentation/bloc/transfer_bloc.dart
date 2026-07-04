import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/failures/transfer_failure.dart';
import '../../domain/repositories/transfer_repository.dart';

part 'transfer_event.dart';
part 'transfer_state.dart';

/// Owns the entire transfer flow: loading data, input validation, confirmation,
/// and execution. The UI only dispatches events and renders steps/states.
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc({required this._repository}) : super(const TransferState()) {
    on<TransferStarted>(_onStarted);
    on<TransferBeneficiarySelected>(_onBeneficiarySelected);
    on<TransferAmountChanged>(_onAmountChanged);
    on<TransferRemarksChanged>(_onRemarksChanged);
    on<TransferReviewRequested>(_onReviewRequested);
    on<TransferEditRequested>(_onEditRequested);
    on<TransferConfirmed>(_onConfirmed);
    on<TransferRestarted>(_onRestarted);
  }

  final TransferRepository _repository;

  Future<void> _onStarted(
    TransferStarted event,
    Emitter<TransferState> emit,
  ) async {
    emit(state.copyWith(step: TransferStep.loading));
    final (List<Beneficiary> beneficiaries, double balance) = await (
      _repository.getBeneficiaries(),
      _repository.getAvailableBalance(),
    ).wait;

    emit(state.copyWith(
      step: TransferStep.input,
      beneficiaries: beneficiaries,
      availableBalance: balance,
    ));
  }

  void _onBeneficiarySelected(
    TransferBeneficiarySelected event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      selectedBeneficiary: event.beneficiary,
      clearBeneficiaryError: true,
    ));
  }

  void _onAmountChanged(
    TransferAmountChanged event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(
      amount: _parseAmount(event.rawAmount),
      clearAmountError: true,
    ));
  }

  void _onRemarksChanged(
    TransferRemarksChanged event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(remarks: event.remarks));
  }

  void _onReviewRequested(
    TransferReviewRequested event,
    Emitter<TransferState> emit,
  ) {
    final String? beneficiaryError =
        state.selectedBeneficiary == null ? 'Please select a beneficiary' : null;
    final String? amountError =
        _validateAmount(state.amount, state.availableBalance);

    // Block the step transition if anything is invalid.
    if (beneficiaryError != null || amountError != null) {
      emit(state.copyWith(
        beneficiaryError: beneficiaryError,
        amountError: amountError,
        clearBeneficiaryError: beneficiaryError == null,
        clearAmountError: amountError == null,
      ));
      return;
    }

    emit(state.copyWith(step: TransferStep.confirmation));
  }

  void _onEditRequested(
    TransferEditRequested event,
    Emitter<TransferState> emit,
  ) {
    emit(state.copyWith(step: TransferStep.input));
  }

  Future<void> _onConfirmed(
    TransferConfirmed event,
    Emitter<TransferState> emit,
  ) async {
    emit(state.copyWith(step: TransferStep.processing));
    try {
      final TransferEntity receipt = await _repository.submitTransfer(
        beneficiary: state.selectedBeneficiary!,
        amount: state.amount,
        remarks: state.remarks,
      );
      emit(state.copyWith(step: TransferStep.success, receipt: receipt));
    } on TransferFailure catch (failure) {
      emit(state.copyWith(
        step: TransferStep.failure,
        failureMessage: failure.message,
      ));
    }
  }

  void _onRestarted(
    TransferRestarted event,
    Emitter<TransferState> emit,
  ) {
    // Reset entry state but keep the already-loaded beneficiaries and balance.
    emit(TransferState(
      step: TransferStep.input,
      beneficiaries: state.beneficiaries,
      availableBalance: state.availableBalance,
    ));
  }

  /// Returns a validation message, or null when the amount is valid.
  String? _validateAmount(double amount, double balance) {
    if (amount <= 0) return 'Enter an amount greater than zero';
    if (amount > balance) return 'Amount exceeds available balance';
    return null;
  }

  /// Parses UI-formatted input (e.g. `1,234`) into a number; 0 when unparsable.
  double _parseAmount(String raw) {
    final String digits = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }
}
