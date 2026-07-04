import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../register/presentation/pages/register_page.dart';

/// Entry gateway: existing users sign in, new users open an account.
class GatewayPage extends StatelessWidget {
  const GatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.textOnPrimary,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Welcome to NovaBank',
                style: AppTypography.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Secure, modern banking in the palm of your hand. '
                'Sign in or open an account in minutes.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              CustomButton(
                label: 'Sign in',
                onPressed: () => _open(context, const LoginPage()),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                label: 'Open an account',
                variant: ButtonVariant.secondary,
                onPressed: () => _open(context, const RegisterPage()),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
