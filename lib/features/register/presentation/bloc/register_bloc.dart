import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/registered_account.dart';
import '../../domain/failures/register_failure.dart';
import '../../domain/repositories/register_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

/// Owns the entire registration wizard: phone/OTP verification (with a resend
/// countdown), eKYC capture, credentials setup and account creation. The UI
/// only dispatches events and renders the current [RegisterStep]/[RegisterState].
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required this._repository}) : super(const RegisterState()) {
    on<RegisterPhoneChanged>(_onPhoneChanged);
    on<RegisterOtpRequested>(_onOtpRequested);
    on<RegisterOtpResendRequested>(_onOtpResendRequested);
    on<RegisterOtpDigitAdded>(_onOtpDigitAdded);
    on<RegisterOtpDigitRemoved>(_onOtpDigitRemoved);
    on<RegisterOtpTicked>(_onOtpTicked);
    on<RegisterIdFrontUploaded>(_onIdFrontUploaded);
    on<RegisterIdBackUploaded>(_onIdBackUploaded);
    on<RegisterFaceScanRequested>(_onFaceScanRequested);
    on<RegisterKycSubmitted>(_onKycSubmitted);
    on<RegisterCredentialsSubmitted>(_onCredentialsSubmitted);
    on<RegisterBackRequested>(_onBackRequested);
  }

  final RegisterRepository _repository;

  /// Length of the OTP code.
  static const int otpLength = 6;

  /// Seconds the user must wait before requesting a new code.
  static const int _resendCountdown = 60;

  /// Raw OTP entry — kept private and never emitted in [RegisterState].
  String _otp = '';

  /// Drives the resend countdown.
  Timer? _otpTimer;

  @override
  Future<void> close() {
    _otpTimer?.cancel();
    return super.close();
  }

  // --- Phone & OTP ---------------------------------------------------------

  void _onPhoneChanged(RegisterPhoneChanged event, Emitter<RegisterState> emit) {
    emit(state.copyWith(phoneNumber: event.phoneNumber, clearPhoneError: true));
  }

  Future<void> _onOtpRequested(
    RegisterOtpRequested event,
    Emitter<RegisterState> emit,
  ) async {
    final String? phoneError = _validatePhone(state.phoneNumber);
    if (phoneError != null) {
      emit(state.copyWith(phoneError: phoneError));
      return;
    }

    emit(state.copyWith(status: RegisterStatus.submitting, clearFailure: true));
    try {
      await _repository.requestOtp(state.phoneNumber);
      _otp = '';
      emit(state.copyWith(
        step: RegisterStep.otp,
        status: RegisterStatus.idle,
        otpDigits: 0,
        otpSecondsRemaining: _resendCountdown,
        clearOtpError: true,
      ));
      _startOtpCountdown();
    } on RegisterFailure catch (failure) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: failure.message,
      ));
    }
  }

  Future<void> _onOtpResendRequested(
    RegisterOtpResendRequested event,
    Emitter<RegisterState> emit,
  ) async {
    if (!state.canResendOtp) return;
    emit(state.copyWith(status: RegisterStatus.submitting));
    try {
      await _repository.requestOtp(state.phoneNumber);
      _otp = '';
      emit(state.copyWith(
        status: RegisterStatus.idle,
        otpDigits: 0,
        otpSecondsRemaining: _resendCountdown,
        clearOtpError: true,
      ));
      _startOtpCountdown();
    } on RegisterFailure catch (failure) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: failure.message,
      ));
    }
  }

  Future<void> _onOtpDigitAdded(
    RegisterOtpDigitAdded event,
    Emitter<RegisterState> emit,
  ) async {
    if (_otp.length >= otpLength || state.isSubmitting) return;

    _otp += event.digit;
    emit(state.copyWith(otpDigits: _otp.length, clearOtpError: true));

    if (_otp.length == otpLength) {
      final String otp = _otp;
      emit(state.copyWith(status: RegisterStatus.submitting));
      try {
        await _repository.verifyOtp(
          phoneNumber: state.phoneNumber,
          otp: otp,
        );
        _otp = '';
        _otpTimer?.cancel();
        emit(state.copyWith(
          step: RegisterStep.kyc,
          status: RegisterStatus.idle,
          otpDigits: 0,
        ));
      } on RegisterFailure catch (failure) {
        _otp = '';
        emit(state.copyWith(
          status: RegisterStatus.idle,
          otpDigits: 0,
          otpError: failure.message,
        ));
      }
    }
  }

  void _onOtpDigitRemoved(
    RegisterOtpDigitRemoved event,
    Emitter<RegisterState> emit,
  ) {
    if (_otp.isEmpty) return;
    _otp = _otp.substring(0, _otp.length - 1);
    emit(state.copyWith(otpDigits: _otp.length, clearOtpError: true));
  }

  void _onOtpTicked(RegisterOtpTicked event, Emitter<RegisterState> emit) {
    final int remaining = state.otpSecondsRemaining - 1;
    if (remaining <= 0) {
      _otpTimer?.cancel();
      emit(state.copyWith(otpSecondsRemaining: 0));
    } else {
      emit(state.copyWith(otpSecondsRemaining: remaining));
    }
  }

  void _startOtpCountdown() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const RegisterOtpTicked()),
    );
  }

  // --- eKYC ----------------------------------------------------------------

  void _onIdFrontUploaded(
    RegisterIdFrontUploaded event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(idFrontUploaded: true, clearKycError: true));
  }

  void _onIdBackUploaded(
    RegisterIdBackUploaded event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(idBackUploaded: true, clearKycError: true));
  }

  Future<void> _onFaceScanRequested(
    RegisterFaceScanRequested event,
    Emitter<RegisterState> emit,
  ) async {
    // Simulate the facial-capture + liveness check.
    emit(state.copyWith(status: RegisterStatus.submitting, clearKycError: true));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    emit(state.copyWith(status: RegisterStatus.idle, faceScanned: true));
  }

  Future<void> _onKycSubmitted(
    RegisterKycSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (!state.isKycComplete) {
      emit(state.copyWith(
        kycError: 'Please complete all verification steps to continue.',
      ));
      return;
    }

    emit(state.copyWith(status: RegisterStatus.submitting, clearFailure: true));
    try {
      await _repository.submitKyc();
      emit(state.copyWith(
        step: RegisterStep.credentials,
        status: RegisterStatus.idle,
      ));
    } on RegisterFailure catch (failure) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: failure.message,
      ));
    }
  }

  // --- Credentials & creation ---------------------------------------------

  Future<void> _onCredentialsSubmitted(
    RegisterCredentialsSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(status: RegisterStatus.submitting, clearFailure: true));
    try {
      final RegisteredAccount account = await _repository.createAccount(
        phoneNumber: state.phoneNumber,
        username: event.username,
        password: event.password,
        pin: event.pin,
      );
      emit(state.copyWith(
        step: RegisterStep.success,
        status: RegisterStatus.idle,
        account: account,
      ));
    } on RegisterFailure catch (failure) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: failure.message,
      ));
    }
  }

  // --- Navigation ----------------------------------------------------------

  void _onBackRequested(
    RegisterBackRequested event,
    Emitter<RegisterState> emit,
  ) {
    // Only the OTP step steps back (to phone entry); other steps are one-way.
    if (state.step == RegisterStep.otp) {
      _otp = '';
      _otpTimer?.cancel();
      emit(state.copyWith(
        step: RegisterStep.phone,
        otpDigits: 0,
        clearOtpError: true,
      ));
    }
  }

  // --- Validation ----------------------------------------------------------

  /// Returns an error message, or null when the phone number is valid.
  String? _validatePhone(String phone) {
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9 || digits.length > 11) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
