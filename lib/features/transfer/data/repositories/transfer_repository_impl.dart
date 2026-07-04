import 'dart:math';

import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/failures/transfer_failure.dart';
import '../../domain/repositories/transfer_repository.dart';

/// In-memory [TransferRepository] with a simulated network delay and a
/// configurable random failure rate (default 5%) for exercising the failure UI.
///
/// [random] and [failureRate] are injectable so tests can force a deterministic
/// success ([failureRate] = 0) or failure ([failureRate] = 1).
class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl({
    Random? random,
    this.failureRate = 0.05,
  }) : _random = random ?? Random();

  final Random _random;

  /// Probability in `[0, 1]` that [submitTransfer] fails with a network error.
  final double failureRate;

  static const double _availableBalance = 12480.75;

  static const List<Beneficiary> _beneficiaries = <Beneficiary>[
    Beneficiary(
      id: 'b1',
      name: 'John Carter',
      accountNumber: '•••• 8842',
      bankName: 'Chase',
    ),
    Beneficiary(
      id: 'b2',
      name: 'Sophia Nguyen',
      accountNumber: '•••• 1197',
      bankName: 'Bank of America',
    ),
    Beneficiary(
      id: 'b3',
      name: 'Michael Lee',
      accountNumber: '•••• 5563',
      bankName: 'Wells Fargo',
    ),
    Beneficiary(
      id: 'b4',
      name: 'Emma Wilson',
      accountNumber: '•••• 3320',
      bankName: 'Citi',
    ),
  ];

  @override
  Future<List<Beneficiary>> getBeneficiaries() async {
    await _simulateLatency();
    return _beneficiaries;
  }

  @override
  Future<double> getAvailableBalance() async {
    await _simulateLatency();
    return _availableBalance;
  }

  @override
  Future<TransferEntity> submitTransfer({
    required Beneficiary beneficiary,
    required double amount,
    required String remarks,
  }) async {
    // Processing takes a little longer than a simple read.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (_random.nextDouble() < failureRate) {
      throw TransferFailure.network;
    }

    return TransferEntity(
      referenceId: _generateReference(),
      beneficiary: beneficiary,
      amount: amount,
      remarks: remarks,
      timestamp: DateTime.now(),
    );
  }

  /// e.g. `TXN-8F3A21C4`.
  String _generateReference() {
    const String hex = '0123456789ABCDEF';
    final String suffix = List<String>.generate(
      8,
      (_) => hex[_random.nextInt(hex.length)],
    ).join();
    return 'TXN-$suffix';
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 500));
}
