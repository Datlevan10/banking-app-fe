part of 'register_bloc.dart';

/// The current step of the registration wizard.
enum RegisterStep { phone, otp, kyc, credentials, success }

/// Async status for the in-flight action of the current step.
enum RegisterStatus { idle, submitting, failure }

/// Immutable registration state.
///
/// Note: the raw OTP, password and PIN are never stored here. The OTP lives in
/// a private field inside the [RegisterBloc] (only [otpDigits] count is
/// exposed); the password/PIN are passed straight through the submit event.
final class RegisterState extends Equatable {
  const RegisterState({
    this.step = RegisterStep.phone,
    this.status = RegisterStatus.idle,
    this.phoneNumber = '',
    this.phoneError,
    this.otpDigits = 0,
    this.otpError,
    this.otpSecondsRemaining = 0,
    this.idFrontUploaded = false,
    this.idBackUploaded = false,
    this.faceScanned = false,
    this.kycError,
    this.account,
    this.errorMessage,
  });

  final RegisterStep step;
  final RegisterStatus status;

  final String phoneNumber;
  final String? phoneError;

  /// How many OTP digits have been entered (the raw value stays in the BLoC).
  final int otpDigits;
  final String? otpError;

  /// Seconds until "Resend code" becomes available (0 = enabled).
  final int otpSecondsRemaining;

  final bool idFrontUploaded;
  final bool idBackUploaded;
  final bool faceScanned;
  final String? kycError;

  /// Populated on the success step.
  final RegisteredAccount? account;

  /// General async failure message (shown as a snackbar).
  final String? errorMessage;

  bool get isSubmitting => status == RegisterStatus.submitting;
  bool get canResendOtp => otpSecondsRemaining == 0;
  bool get isKycComplete => idFrontUploaded && idBackUploaded && faceScanned;

  RegisterState copyWith({
    RegisterStep? step,
    RegisterStatus? status,
    String? phoneNumber,
    String? phoneError,
    int? otpDigits,
    String? otpError,
    int? otpSecondsRemaining,
    bool? idFrontUploaded,
    bool? idBackUploaded,
    bool? faceScanned,
    String? kycError,
    RegisteredAccount? account,
    String? errorMessage,
    bool clearPhoneError = false,
    bool clearOtpError = false,
    bool clearKycError = false,
    bool clearFailure = false,
  }) {
    return RegisterState(
      step: step ?? this.step,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      otpDigits: otpDigits ?? this.otpDigits,
      otpError: clearOtpError ? null : (otpError ?? this.otpError),
      otpSecondsRemaining: otpSecondsRemaining ?? this.otpSecondsRemaining,
      idFrontUploaded: idFrontUploaded ?? this.idFrontUploaded,
      idBackUploaded: idBackUploaded ?? this.idBackUploaded,
      faceScanned: faceScanned ?? this.faceScanned,
      kycError: clearKycError ? null : (kycError ?? this.kycError),
      account: account ?? this.account,
      errorMessage: clearFailure ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    step,
    status,
    phoneNumber,
    phoneError,
    otpDigits,
    otpError,
    otpSecondsRemaining,
    idFrontUploaded,
    idBackUploaded,
    faceScanned,
    kycError,
    account,
    errorMessage,
  ];
}
