import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns all login business logic: biometric checks, PIN assembly/validation,
/// and credential sign-in. The UI only dispatches events and renders states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this._repository}) : super(const AuthState()) {
    on<AuthBiometricAvailabilityRequested>(_onBiometricAvailabilityRequested);
    on<AuthModeToggled>(_onModeToggled);
    on<AuthBiometricRequested>(_onBiometricRequested);
    on<AuthPinDigitAdded>(_onPinDigitAdded);
    on<AuthPinDigitRemoved>(_onPinDigitRemoved);
    on<AuthCredentialsSubmitted>(_onCredentialsSubmitted);
  }

  final AuthRepository _repository;

  /// The raw in-progress PIN. Kept private and short-lived: it is never placed
  /// in [AuthState], and is wiped after a submit attempt (success or failure)
  /// and whenever the sign-in mode changes.
  String _pin = '';

  /// Number of digits required for a complete PIN.
  static const int pinLength = 6;

  Future<void> _onBiometricAvailabilityRequested(
    AuthBiometricAvailabilityRequested event,
    Emitter<AuthState> emit,
  ) async {
    final bool available = await _repository.isBiometricAvailable();
    emit(state.copyWith(isBiometricAvailable: available));
  }

  void _onModeToggled(AuthModeToggled event, Emitter<AuthState> emit) {
    final AuthMode next =
        state.mode == AuthMode.pin ? AuthMode.credentials : AuthMode.pin;
    // Reset transient entry state when switching methods.
    _pin = '';
    emit(state.copyWith(
      mode: next,
      enteredDigits: 0,
      status: AuthStatus.initial,
      clearError: true,
    ));
  }

  Future<void> _onBiometricRequested(
    AuthBiometricRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthentication(emit, _repository.authenticateWithBiometrics);
  }

  Future<void> _onPinDigitAdded(
    AuthPinDigitAdded event,
    Emitter<AuthState> emit,
  ) async {
    // Ignore extra taps once the PIN is full or while authenticating.
    if (_pin.length >= pinLength ||
        state.status == AuthStatus.authenticating) {
      return;
    }

    _pin += event.digit;
    emit(state.copyWith(enteredDigits: _pin.length, clearError: true));

    // Auto-submit as soon as the PIN is complete.
    if (_pin.length == pinLength) {
      final String pin = _pin;
      await _runAuthentication(
        emit,
        () => _repository.authenticateWithPin(pin),
        onFailureResetPin: true,
      );
    }
  }

  void _onPinDigitRemoved(
    AuthPinDigitRemoved event,
    Emitter<AuthState> emit,
  ) {
    if (_pin.isEmpty) return;
    _pin = _pin.substring(0, _pin.length - 1);
    emit(state.copyWith(enteredDigits: _pin.length, clearError: true));
  }

  Future<void> _onCredentialsSubmitted(
    AuthCredentialsSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthentication(
      emit,
      () => _repository.authenticateWithCredentials(
        username: event.username,
        password: event.password,
      ),
    );
  }

  /// Shared runner: flips to [AuthStatus.authenticating], invokes [attempt],
  /// and maps the result to success/failure — keeping every handler uniform.
  Future<void> _runAuthentication(
    Emitter<AuthState> emit,
    Future<AuthUser> Function() attempt, {
    bool onFailureResetPin = false,
  }) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));
    try {
      final AuthUser user = await attempt();
      // Wipe the raw PIN as soon as it is no longer needed.
      _pin = '';
      emit(state.copyWith(status: AuthStatus.success, user: user));
    } on AuthException catch (error) {
      if (onFailureResetPin) _pin = '';
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: error.message,
        enteredDigits: onFailureResetPin ? 0 : null,
      ));
    }
  }
}
