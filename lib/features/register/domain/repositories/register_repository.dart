import '../entities/registered_account.dart';

/// Contract for the registration/onboarding flow.
///
/// Each step's async action lives here; the BLoC orchestrates them without
/// knowing how the SMS is sent, how documents are stored, or how the account
/// is provisioned. Methods throw a `RegisterFailure` on error.
abstract interface class RegisterRepository {
  /// Simulate sending an OTP SMS to [phoneNumber].
  Future<void> requestOtp(String phoneNumber);

  /// Validate the [otp] entered for [phoneNumber].
  Future<void> verifyOtp({required String phoneNumber, required String otp});

  /// Submit the captured eKYC artefacts (ID front/back + facial scan).
  Future<void> submitKyc();

  /// Provision the account and return its details.
  Future<RegisteredAccount> createAccount({
    required String phoneNumber,
    required String username,
    required String password,
    required String pin,
  });
}
