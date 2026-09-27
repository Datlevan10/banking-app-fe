part of 'transfer_bloc.dart';

/// Events driving the multi-step transfer flow.
sealed class TransferEvent extends Equatable {
  const TransferEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Load beneficiaries and the available balance (dispatched on screen open).
final class TransferStarted extends TransferEvent {
  const TransferStarted();
}

/// Open the flow pre-populated from external data (e.g. a scanned QR code).
final class TransferPrefillRequested extends TransferEvent {
  const TransferPrefillRequested(this.prefill);

  final TransferPrefill prefill;

  @override
  List<Object?> get props => <Object?>[prefill];
}

/// User picked a beneficiary from the quick list.
final class TransferBeneficiarySelected extends TransferEvent {
  const TransferBeneficiarySelected(this.beneficiary);

  final Beneficiary beneficiary;

  @override
  List<Object?> get props => <Object?>[beneficiary];
}

/// Raw amount text changed (parsed to a number inside the BLoC).
final class TransferAmountChanged extends TransferEvent {
  const TransferAmountChanged(this.rawAmount);

  final String rawAmount;

  @override
  List<Object?> get props => <Object?>[rawAmount];
}

/// Remarks text changed.
final class TransferRemarksChanged extends TransferEvent {
  const TransferRemarksChanged(this.remarks);

  final String remarks;

  @override
  List<Object?> get props => <Object?>[remarks];
}

/// Validate the input and, if valid, advance to the confirmation step.
final class TransferReviewRequested extends TransferEvent {
  const TransferReviewRequested();
}

/// Go back from confirmation to the input step to edit details.
final class TransferEditRequested extends TransferEvent {
  const TransferEditRequested();
}

/// Confirm and execute the transfer.
final class TransferConfirmed extends TransferEvent {
  const TransferConfirmed();
}

/// Start a new transfer, keeping the loaded beneficiaries and balance.
final class TransferRestarted extends TransferEvent {
  const TransferRestarted();
}
