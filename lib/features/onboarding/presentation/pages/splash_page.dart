import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'gateway_page.dart';

/// Branded splash shown while the app "initialises", then routes to the
/// [GatewayPage]. The delay is a pure presentation concern (a simulated
/// bootstrap), so it lives in local widget state rather than a BLoC.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// How long the splash is displayed before navigating.
  static const Duration initDuration = Duration(milliseconds: 2200);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashPage.initDuration, _goToGateway);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToGateway() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const GatewayPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 52,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'NovaBank',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Banking, reimagined',
              style: AppTypography.body.copyWith(
                color: AppColors.textOnPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl * 2),
            const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
