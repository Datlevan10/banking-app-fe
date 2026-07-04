/// Domain-level failure for the registration flow.
///
/// The data layer maps any low-level error into one of these user-safe
/// failures, keeping the presentation layer transport-agnostic.
class RegisterFailure implements Exception {
  const RegisterFailure(this.message);

  /// User-safe message the UI can display directly.
  final String message;

  static const RegisterFailure invalidOtp = RegisterFailure(
    'The code you entered is incorrect. Please try again.',
  );

  static const RegisterFailure network = RegisterFailure(
    'Something went wrong. Please check your connection and try again.',
  );

  @override
  String toString() => 'RegisterFailure: $message';
}
