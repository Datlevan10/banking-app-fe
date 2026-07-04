part of 'home_bloc.dart';

/// Events the dashboard can dispatch to its [HomeBloc].
sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Load (or reload) the account and recent transactions.
final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Toggle whether the balance figure is shown or masked.
final class BalanceVisibilityToggled extends HomeEvent {
  const BalanceVisibilityToggled();
}
