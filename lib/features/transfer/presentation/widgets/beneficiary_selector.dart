import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/beneficiary.dart';

/// Horizontal quick-select list of beneficiaries with an avatar per payee.
///
/// Presentational only: selection is reported via [onSelected]; the selected
/// state comes from the parent (BLoC).
class BeneficiarySelector extends StatelessWidget {
  const BeneficiarySelector({
    super.key,
    required this.beneficiaries,
    required this.selected,
    required this.onSelected,
  });

  final List<Beneficiary> beneficiaries;
  final Beneficiary? selected;
  final ValueChanged<Beneficiary> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: beneficiaries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Beneficiary beneficiary = beneficiaries[index];
          return _BeneficiaryAvatar(
            beneficiary: beneficiary,
            isSelected: beneficiary == selected,
            onTap: () => onSelected(beneficiary),
          );
        },
      ),
    );
  }
}

class _BeneficiaryAvatar extends StatelessWidget {
  const _BeneficiaryAvatar({
    required this.beneficiary,
    required this.isSelected,
    required this.onTap,
  });

  final Beneficiary beneficiary;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          children: <Widget>[
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  beneficiary.initials,
                  style: AppTypography.title.copyWith(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              beneficiary.name.split(' ').first,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
