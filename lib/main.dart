import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/observers/app_bloc_observer.dart';

void main() {
  // Single audit/telemetry hook for every BLoC in the app.
  Bloc.observer = const AppBlocObserver();
  runApp(const BankingApp());
}
