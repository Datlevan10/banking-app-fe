import '../entities/account.dart';
import '../entities/transaction.dart';

/// Abstract contract the presentation layer (BLoC) depends on.
///
/// The domain declares *what* it needs; the data layer decides *how* (REST,
/// GraphQL, local cache…). This inversion keeps the BLoC free of any I/O
/// concerns and trivially testable with a mock.
abstract interface class HomeRepository {
  /// The primary account whose balance is shown on the dashboard.
  Future<Account> getPrimaryAccount();

  /// Most recent transactions, newest first.
  Future<List<Transaction>> getRecentTransactions();
}
