import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Centralised observer for every [Bloc]/[Cubit] in the app.
///
/// Provides a single audit/telemetry hook for financial state changes — useful
/// for a banking app's debugging and (eventually) compliance trail. Logging is
/// gated to debug builds so it never runs in release.
///
/// Install once at startup: `Bloc.observer = const AppBlocObserver();`
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _log('CREATE', bloc, '');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('EVENT', bloc, event.runtimeType.toString());
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _log(
      'TRANSITION',
      bloc,
      '${transition.event.runtimeType}: '
          '${transition.currentState.runtimeType} → '
          '${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _log('ERROR', bloc, error.toString(), isError: true);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _log('CLOSE', bloc, '');
  }

  void _log(String tag, BlocBase<dynamic> bloc, String detail,
      {bool isError = false}) {
    if (!kDebugMode) return;
    final String name = bloc.runtimeType.toString();
    final String line =
        detail.isEmpty ? '[$tag] $name' : '[$tag] $name • $detail';
    developer.log(
      line,
      name: 'BLoC',
      level: isError ? 1000 : 0,
    );
  }
}
