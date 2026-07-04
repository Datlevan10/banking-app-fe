part of 'register_bloc.dart';

/// Events driving the multi-step registration wizard.
sealed class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => <Object?>[];
}

// --- Step 1: Phone & OTP ---------------------------------------------------

/// Phone number field changed.
final class RegisterPhoneChanged extends RegisterEvent {
  const RegisterPhoneChanged(this.phoneNumber);

  final String phoneNumber;

  @override
  List<Object?> get props => <Object?>[phoneNumber];
}

/// Validate the phone number and request an OTP SMS.
final class RegisterOtpRequested extends RegisterEvent {
  const RegisterOtpRequested();
}

/// Re-send the OTP (only allowed once the countdown reaches zero).
final class RegisterOtpResendRequested extends RegisterEvent {
  const RegisterOtpResendRequested();
}

/// Append a digit to the in-progress OTP.
final class RegisterOtpDigitAdded extends RegisterEvent {
  const RegisterOtpDigitAdded(this.digit);

  final String digit;

  @override
  List<Object?> get props => <Object?>[digit];
}

/// Remove the last OTP digit.
final class RegisterOtpDigitRemoved extends RegisterEvent {
  const RegisterOtpDigitRemoved();
}

/// Internal one-second tick for the resend countdown.
final class RegisterOtpTicked extends RegisterEvent {
  const RegisterOtpTicked();
}

// --- Step 2: eKYC ----------------------------------------------------------

/// National ID front captured.
final class RegisterIdFrontUploaded extends RegisterEvent {
  const RegisterIdFrontUploaded();
}

/// National ID back captured.
final class RegisterIdBackUploaded extends RegisterEvent {
  const RegisterIdBackUploaded();
}

/// Facial scan performed (simulated).
final class RegisterFaceScanRequested extends RegisterEvent {
  const RegisterFaceScanRequested();
}

/// Submit the eKYC artefacts and advance to credentials setup.
final class RegisterKycSubmitted extends RegisterEvent {
  const RegisterKycSubmitted();
}

// --- Step 3: Credentials ---------------------------------------------------

/// Submit username, password and transaction PIN to create the account.
final class RegisterCredentialsSubmitted extends RegisterEvent {
  const RegisterCredentialsSubmitted({
    required this.username,
    required this.password,
    required this.pin,
  });

  final String username;
  final String password;
  final String pin;

  @override
  List<Object?> get props => <Object?>[username, password, pin];
}

// --- Navigation ------------------------------------------------------------

/// Go back one step within the wizard.
final class RegisterBackRequested extends RegisterEvent {
  const RegisterBackRequested();
}
