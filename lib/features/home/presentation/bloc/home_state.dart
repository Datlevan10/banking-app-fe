part of 'home_bloc.dart';

/// Lifecycle status of the dashboard data.
enum HomeStatus { initial, loading, success, failure }

/// Immutable state rendered by the dashboard UI.
///
/// A single state class with a [status] enum keeps the widget layer simple:
/// it switches on [status] and reads whatever data is available.
final class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.initial,
    this.account,
    this.transactions = const <Transaction>[],
    this.isBalanceVisible = false,
    this.errorMessage,
  });

  final HomeStatus status;
  final Account? account;
  final List<Transaction> transactions;

  /// Balance starts hidden by default — a sensible security default.
  final bool isBalanceVisible;
  final String? errorMessage;

  HomeState copyWith({
    HomeStatus? status,
    Account? account,
    List<Transaction>? transactions,
    bool? isBalanceVisible,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      account: account ?? this.account,
      transactions: transactions ?? this.transactions,
      isBalanceVisible: isBalanceVisible ?? this.isBalanceVisible,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    account,
    transactions,
    isBalanceVisible,
    errorMessage,
  ];
}
