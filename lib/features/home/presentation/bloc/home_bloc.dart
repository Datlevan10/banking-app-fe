import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/home_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Owns all dashboard business logic.
///
/// The UI dispatches [HomeEvent]s and renders [HomeState]s — it never touches
/// the repository directly. This is the strict UI/logic separation required by
/// the spec.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  // `this._repository` is an initializing formal: callers still pass the
  // public name `repository:`, keeping the field private and the API clean.
  HomeBloc({required this._repository}) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<BalanceVisibilityToggled>(_onVisibilityToggled);
  }

  final HomeRepository _repository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      // Fetch account and transactions concurrently.
      final (Account account, List<Transaction> transactions) = await (
        _repository.getPrimaryAccount(),
        _repository.getRecentTransactions(),
      ).wait;

      emit(state.copyWith(
        status: HomeStatus.success,
        account: account,
        transactions: transactions,
      ));
    } on Object catch (error) {
      emit(state.copyWith(
        status: HomeStatus.failure,
        errorMessage: 'Failed to load your account. $error',
      ));
    }
  }

  void _onVisibilityToggled(
    BalanceVisibilityToggled event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(isBalanceVisible: !state.isBalanceVisible));
  }
}
