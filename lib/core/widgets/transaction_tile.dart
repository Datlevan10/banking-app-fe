import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/home/domain/entities/transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency_formatter.dart';

/// A single row in the transaction history list.
///
/// Color semantics (per requirements):
/// - income  -> green amount text + green leading icon,
/// - expense -> red amount text + red leading icon.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.isIncome;
    final Color accent = isIncome ? AppColors.income : AppColors.expense;
    final Color surface =
        isIncome ? AppColors.incomeSurface : AppColors.expenseSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              // Leading directional icon.
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Title + category/date.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      transaction.title,
                      style: AppTypography.bodyStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${transaction.category} • '
                      '${DateFormat('MMM d').format(transaction.date)}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Signed amount, colored by direction.
              Text(
                CurrencyFormatter.formatSigned(transaction.signedAmount),
                style: AppTypography.bodyStrong.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
