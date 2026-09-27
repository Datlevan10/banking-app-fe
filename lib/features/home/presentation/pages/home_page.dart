import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/transaction_tile.dart';
import '../../../qr_scan/presentation/pages/qr_scan_page.dart';
import '../../../transfer/presentation/pages/transfer_page.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../bloc/home_bloc.dart';
import '../widgets/quick_actions_grid.dart';

/// Dashboard screen.
///
/// This widget only creates the [HomeBloc] and delegates rendering to
/// [_HomeView]. Keeping construction and view separate makes the view easy to
/// test with a mocked bloc.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => HomeBloc(
        repository: const HomeRepositoryImpl(),
      )..add(const HomeStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good morning, Van Dat'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (BuildContext context, HomeState state) {
          return switch (state.status) {
            HomeStatus.initial ||
            HomeStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            HomeStatus.failure => _ErrorView(
                message: state.errorMessage ?? 'Something went wrong.',
                onRetry: () =>
                    context.read<HomeBloc>().add(const HomeStarted()),
              ),
            HomeStatus.success => _DashboardContent(state: state),
          };
        },
      ),
    );
  }
}

/// The populated dashboard (balance, quick actions, recent transactions).
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final HomeBloc bloc = context.read<HomeBloc>();

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const HomeStarted()),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        children: <Widget>[
          // --- Balance card ------------------------------------------------
          BalanceCard(
            holderName: state.account!.holderName,
            maskedNumber: state.account!.maskedNumber,
            balance: state.account!.balance,
            isBalanceVisible: state.isBalanceVisible,
            onToggleVisibility: () =>
                bloc.add(const BalanceVisibilityToggled()),
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Quick actions ----------------------------------------------
          QuickActionsGrid(
            actions: <QuickAction>[
              QuickAction(
                label: 'Transfer',
                icon: Icons.swap_horiz_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TransferPage(),
                  ),
                ),
              ),
              QuickAction(
                label: 'Top-up',
                icon: Icons.add_card_rounded,
                onTap: () {},
              ),
              QuickAction(
                label: 'Bills',
                icon: Icons.receipt_long_rounded,
                onTap: () {},
              ),
              QuickAction(
                label: 'QR Scan',
                icon: Icons.qr_code_scanner_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const QrScanPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // --- Recent transactions header ---------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Recent transactions', style: AppTypography.title),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // --- Transaction list -------------------------------------------
          // Non-scrollable: it lives inside the outer ListView.
          ...state.transactions.map(
            (transaction) => TransactionTile(
              transaction: transaction,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple retryable error view.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.expense,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
