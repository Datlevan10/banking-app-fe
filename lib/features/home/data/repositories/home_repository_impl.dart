import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/home_repository.dart';

/// In-memory implementation used for development and UI wiring.
///
/// Swap this for a real remote data source (Dio/GraphQL) without touching the
/// BLoC or the UI — that is the payoff of depending on [HomeRepository].
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl();

  @override
  Future<Account> getPrimaryAccount() async {
    await _simulateLatency();
    return const Account(
      id: 'acc_01',
      holderName: 'Van Dat',
      maskedNumber: '•••• 4921',
      balance: 12480.75,
    );
  }

  @override
  Future<List<Transaction>> getRecentTransactions() async {
    await _simulateLatency();
    return <Transaction>[
      Transaction(
        id: 't1',
        title: 'Salary — ACME Corp',
        category: 'Income',
        amount: 4200,
        type: TransactionType.income,
        date: DateTime(2026, 7, 1),
      ),
      Transaction(
        id: 't2',
        title: 'Apple Store',
        category: 'Shopping',
        amount: 1299,
        type: TransactionType.expense,
        date: DateTime(2026, 6, 29),
      ),
      Transaction(
        id: 't3',
        title: 'Grab Transport',
        category: 'Transport',
        amount: 12.5,
        type: TransactionType.expense,
        date: DateTime(2026, 6, 28),
      ),
      Transaction(
        id: 't4',
        title: 'Refund — Booking.com',
        category: 'Travel',
        amount: 340,
        type: TransactionType.income,
        date: DateTime(2026, 6, 27),
      ),
      Transaction(
        id: 't5',
        title: 'Electricity Bill',
        category: 'Utilities',
        amount: 86.2,
        type: TransactionType.expense,
        date: DateTime(2026, 6, 25),
      ),
    ];
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 600));
}
