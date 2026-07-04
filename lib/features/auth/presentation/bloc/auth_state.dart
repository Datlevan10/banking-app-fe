part of 'auth_bloc.dart';

/// Where the login flow currently is.
enum AuthStatus { initial, authenticating, success, failure }

/// Which sign-in method the UI is presenting.
enum AuthMode { pin, credentials }

/// Immutable login state rendered by the [LoginPage].
final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.mode = AuthMode.pin,
    this.enteredDigits = 0,
    this.isBiometricAvailable = false,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthMode mode;

  /// How many PIN digits have been entered so far. The raw PIN itself is kept
  /// in a private field inside the [AuthBloc] and is never emitted — the UI
  /// only needs this count to render the dot indicators.
  final int enteredDigits;
  final bool isBiometricAvailable;
  final AuthUser? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AuthMode? mode,
    int? enteredDigits,
    bool? isBiometricAvailable,
    AuthUser? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      enteredDigits: enteredDigits ?? this.enteredDigits,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    mode,
    enteredDigits,
    isBiometricAvailable,
    user,
    errorMessage,
  ];
}
