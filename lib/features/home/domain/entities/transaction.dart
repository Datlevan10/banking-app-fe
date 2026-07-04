import 'package:equatable/equatable.dart';

/// Direction of money movement, used to drive the UI color semantics
/// (green for income, red for expense).
enum TransactionType { income, expense }

/// A single account transaction.
///
/// Pure domain entity: no Flutter, no JSON, no formatting logic. It is the
/// stable contract the presentation layer renders and the data layer maps to.
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  final String id;
  final String title;
  final String category;

  /// Always a positive magnitude; [type] carries the direction.
  final double amount;
  final TransactionType type;
  final DateTime date;

  bool get isIncome => type == TransactionType.income;

  /// Signed value: positive for income, negative for expense.
  double get signedAmount => isIncome ? amount : -amount;

  @override
  List<Object?> get props => <Object?>[id, title, category, amount, type, date];
}
