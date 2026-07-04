import 'dart:math';

import '../../domain/entities/registered_account.dart';
import '../../domain/failures/register_failure.dart';
import '../../domain/repositories/register_repository.dart';

/// In-memory [RegisterRepository] for development.
///
/// [random] is injectable so tests can generate a deterministic account
/// number. The demo OTP is fixed; swap these branches for real API calls.
class RegisterRepositoryImpl implements RegisterRepository {
  RegisterRepositoryImpl({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// The OTP the simulated SMS always "sends".
  static const String demoOtp = '123456';

  @override
  Future<void> requestOtp(String phoneNumber) async {
    await _simulateLatency();
    // In production this would trigger an SMS gateway call.
  }

  @override
  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    await _simulateLatency();
    if (otp != demoOtp) throw RegisterFailure.invalidOtp;
  }

  @override
  Future<void> submitKyc() async {
    // Document upload + facial match verification takes a little longer.
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  @override
  Future<RegisteredAccount> createAccount({
    required String phoneNumber,
    required String username,
    required String password,
    required String pin,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return RegisteredAccount(
      accountNumber: _generateAccountNumber(),
      username: username,
      createdAt: DateTime.now(),
    );
  }

  /// A 12-digit account number, grouped as `XXXX XXXX XXXX`.
  String _generateAccountNumber() {
    final String digits = List<int>.generate(12, (_) => _random.nextInt(10))
        .join();
    return '${digits.substring(0, 4)} '
        '${digits.substring(4, 8)} '
        '${digits.substring(8, 12)}';
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 700));
}
