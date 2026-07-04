import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency_formatter.dart';

/// Premium account card shown at the top of the dashboard.
///
/// Features:
/// - gradient background,
/// - masked account number,
/// - hide/show balance toggle (the visibility state is owned by the parent so
///   it survives rebuilds and can be persisted/secured if needed).
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.holderName,
    required this.maskedNumber,
    required this.balance,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
  });

  final String holderName;
  final String maskedNumber;
  final double balance;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Available balance',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                ),
              ),
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.textOnPrimary,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Balance figure + visibility toggle.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  isBalanceVisible
                      ? CurrencyFormatter.format(balance)
                      : CurrencyFormatter.masked(),
                  style: AppTypography.balance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onToggleVisibility,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Footer: holder + masked number.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _Footnote(label: 'Card holder', value: holderName),
              _Footnote(label: 'Account', value: maskedNumber),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small two-line label/value pair used in the card footer.
class _Footnote extends StatelessWidget {
  const _Footnote({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textOnPrimary.withValues(alpha: 0.7),
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodyStrong.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
      ],
    );
  }
}
