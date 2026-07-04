part of 'transfer_bloc.dart';

/// The step the transfer wizard is currently on.
enum TransferStep { loading, input, confirmation, processing, success, failure }

/// Immutable state for the transfer flow.
final class TransferState extends Equatable {
  const TransferState({
    this.step = TransferStep.loading,
    this.beneficiaries = const <Beneficiary>[],
    this.availableBalance = 0,
    this.selectedBeneficiary,
    this.amount = 0,
    this.remarks = '',
    this.amountError,
    this.beneficiaryError,
    this.receipt,
    this.failureMessage,
  });

  final TransferStep step;
  final List<Beneficiary> beneficiaries;
  final double availableBalance;
  final Beneficiary? selectedBeneficiary;
  final double amount;
  final String remarks;

  /// Field-level validation messages (null when valid).
  final String? amountError;
  final String? beneficiaryError;

  /// Populated on the success step.
  final TransferEntity? receipt;

  /// Populated on the failure step.
  final String? failureMessage;

  TransferState copyWith({
    TransferStep? step,
    List<Beneficiary>? beneficiaries,
    double? availableBalance,
    Beneficiary? selectedBeneficiary,
    double? amount,
    String? remarks,
    String? amountError,
    String? beneficiaryError,
    TransferEntity? receipt,
    String? failureMessage,
    bool clearAmountError = false,
    bool clearBeneficiaryError = false,
  }) {
    return TransferState(
      step: step ?? this.step,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      availableBalance: availableBalance ?? this.availableBalance,
      selectedBeneficiary: selectedBeneficiary ?? this.selectedBeneficiary,
      amount: amount ?? this.amount,
      remarks: remarks ?? this.remarks,
      amountError: clearAmountError ? null : (amountError ?? this.amountError),
      beneficiaryError: clearBeneficiaryError
          ? null
          : (beneficiaryError ?? this.beneficiaryError),
      receipt: receipt ?? this.receipt,
      failureMessage: failureMessage ?? this.failureMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    step,
    beneficiaries,
    availableBalance,
    selectedBeneficiary,
    amount,
    remarks,
    amountError,
    beneficiaryError,
    receipt,
    failureMessage,
  ];
}
