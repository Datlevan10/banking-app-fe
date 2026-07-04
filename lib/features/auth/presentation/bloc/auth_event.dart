part of 'auth_bloc.dart';

/// Events the login screen can dispatch to its [AuthBloc].
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Query the device for biometric availability (dispatched on screen load).
final class AuthBiometricAvailabilityRequested extends AuthEvent {
  const AuthBiometricAvailabilityRequested();
}

/// Switch between PIN and username/password sign-in modes.
final class AuthModeToggled extends AuthEvent {
  const AuthModeToggled();
}

/// Trigger the OS biometric prompt.
final class AuthBiometricRequested extends AuthEvent {
  const AuthBiometricRequested();
}

/// Append a digit to the in-progress PIN (from the on-screen keypad).
final class AuthPinDigitAdded extends AuthEvent {
  const AuthPinDigitAdded(this.digit);

  final String digit;

  @override
  List<Object?> get props => <Object?>[digit];
}

/// Remove the last entered PIN digit (backspace).
final class AuthPinDigitRemoved extends AuthEvent {
  const AuthPinDigitRemoved();
}

/// Submit standard username + password credentials.
final class AuthCredentialsSubmitted extends AuthEvent {
  const AuthCredentialsSubmitted({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  List<Object?> get props => <Object?>[username, password];
}
