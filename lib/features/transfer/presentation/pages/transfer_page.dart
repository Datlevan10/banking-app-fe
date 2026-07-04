import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/repositories/transfer_repository_impl.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../bloc/transfer_bloc.dart';
import '../widgets/beneficiary_selector.dart';
import '../widgets/summary_row.dart';

/// Money-transfer screen: a three-step wizard (input → confirmation →
/// success/failure receipt) driven entirely by [TransferBloc].
class TransferPage extends StatelessWidget {
  const TransferPage({super.key, this.repository});

  /// Optional injection point for tests; falls back to the default impl.
  final TransferRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransferBloc>(
      create: (_) => TransferBloc(
        repository: repository ?? TransferRepositoryImpl(),
      )..add(const TransferStarted()),
      child: const _TransferView(),
    );
  }
}

class _TransferView extends StatelessWidget {
  const _TransferView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransferBloc, TransferState>(
      builder: (BuildContext context, TransferState state) {
        return Scaffold(
          appBar: _buildAppBar(context, state.step),
          body: SafeArea(
            child: switch (state.step) {
              TransferStep.loading =>
                const Center(child: CircularProgressIndicator()),
              TransferStep.input => _InputStep(state: state),
              TransferStep.confirmation => _ConfirmationStep(state: state),
              TransferStep.processing => const _ProcessingView(),
              TransferStep.success => _StatusStep(state: state, isSuccess: true),
              TransferStep.failure =>
                _StatusStep(state: state, isSuccess: false),
            },
          ),
        );
      },
    );
  }

  /// Only the input and confirmation steps show an app bar.
  PreferredSizeWidget? _buildAppBar(BuildContext context, TransferStep step) {
    switch (step) {
      case TransferStep.input:
        return AppBar(title: const Text('Transfer'));
      case TransferStep.confirmation:
        return AppBar(
          title: const Text('Confirm transfer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.read<TransferBloc>().add(const TransferEditRequested()),
          ),
        );
      case TransferStep.loading:
      case TransferStep.processing:
      case TransferStep.success:
      case TransferStep.failure:
        return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Step 1: Input
// ---------------------------------------------------------------------------

/// Stateful because it owns the text controllers; all logic stays in the BLoC.
class _InputStep extends StatefulWidget {
  const _InputStep({required this.state});

  final TransferState state;

  @override
  State<_InputStep> createState() => _InputStepState();
}

class _InputStepState extends State<_InputStep> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TransferBloc bloc = context.read<TransferBloc>();
    final TransferState state = widget.state;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.lg,
      ),
      children: <Widget>[
        Text('Send to', style: AppTypography.title),
        const SizedBox(height: AppSpacing.md),
        BeneficiarySelector(
          beneficiaries: state.beneficiaries,
          selected: state.selectedBeneficiary,
          onSelected: (beneficiary) =>
              bloc.add(TransferBeneficiarySelected(beneficiary)),
        ),
        _FieldError(message: state.beneficiaryError),
        const SizedBox(height: AppSpacing.xl),

        // Amount ----------------------------------------------------------
        CustomTextField.currency(
          label: 'Amount',
          controller: _amountController,
          onChanged: (value) => bloc.add(TransferAmountChanged(value)),
        ),
        _FieldError(message: state.amountError),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Available balance: '
          '${CurrencyFormatter.format(state.availableBalance)}',
          style: AppTypography.caption,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Remarks ---------------------------------------------------------
        CustomTextField(
          label: 'Remarks (optional)',
          controller: _remarksController,
          hintText: 'What is this for?',
          onChanged: (value) => bloc.add(TransferRemarksChanged(value)),
        ),
        const SizedBox(height: AppSpacing.xxl),

        CustomButton(
          label: 'Review transfer',
          onPressed: () => bloc.add(const TransferReviewRequested()),
        ),
      ],
    );
  }
}

/// Inline field-level error text; renders nothing when [message] is null.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message!,
        style: AppTypography.caption.copyWith(color: AppColors.expense),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Confirmation
// ---------------------------------------------------------------------------

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({required this.state});

  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final TransferBloc bloc = context.read<TransferBloc>();
    final beneficiary = state.selectedBeneficiary!;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.lg,
            ),
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    Text('You are sending', style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      CurrencyFormatter.format(state.amount),
                      style: AppTypography.displayLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: <Widget>[
                    SummaryRow(label: 'To', value: beneficiary.name),
                    SummaryRow(label: 'Account', value: beneficiary.accountNumber),
                    SummaryRow(label: 'Bank', value: beneficiary.bankName),
                    SummaryRow(
                      label: 'Remarks',
                      value: state.remarks.isEmpty ? '—' : state.remarks,
                    ),
                    const Divider(height: AppSpacing.xl),
                    SummaryRow(
                      label: 'Total',
                      value: CurrencyFormatter.format(state.amount),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Row(
            children: <Widget>[
              Expanded(
                child: CustomButton(
                  label: 'Edit',
                  variant: ButtonVariant.secondary,
                  onPressed: () => bloc.add(const TransferEditRequested()),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: CustomButton(
                  label: 'Confirm & send',
                  onPressed: () => bloc.add(const TransferConfirmed()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Processing
// ---------------------------------------------------------------------------

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Processing your transfer…', style: AppTypography.body),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Success / Failure receipt
// ---------------------------------------------------------------------------

class _StatusStep extends StatelessWidget {
  const _StatusStep({required this.state, required this.isSuccess});

  final TransferState state;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final TransferBloc bloc = context.read<TransferBloc>();

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.xxl,
            ),
            children: <Widget>[
              _StatusHeader(isSuccess: isSuccess, state: state),
              const SizedBox(height: AppSpacing.xl),
              if (isSuccess && state.receipt != null)
                _ReceiptCard(receipt: state.receipt!)
              else if (!isSuccess)
                Center(
                  child: Text(
                    state.failureMessage ?? 'Something went wrong.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: <Widget>[
              if (isSuccess)
                CustomButton(
                  label: 'Share receipt',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => _shareReceipt(context, state.receipt!),
                )
              else
                CustomButton(
                  label: 'Try again',
                  onPressed: () => bloc.add(const TransferRestarted()),
                ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                label: 'Back to home',
                variant: ButtonVariant.secondary,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Copies a formatted receipt to the clipboard as a share fallback (keeps the
  /// project dependency-free; swap for `share_plus` when a native sheet is
  /// wanted).
  Future<void> _shareReceipt(
    BuildContext context,
    TransferEntity receipt,
  ) async {
    final String text = 'Transfer receipt\n'
        'Ref: ${receipt.referenceId}\n'
        'To: ${receipt.beneficiary.name} (${receipt.beneficiary.accountNumber})\n'
        'Amount: ${CurrencyFormatter.format(receipt.amount)}\n'
        'Date: ${DateFormat('MMM d, y • HH:mm').format(receipt.timestamp)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Receipt copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.isSuccess, required this.state});

  final bool isSuccess;
  final TransferState state;

  @override
  Widget build(BuildContext context) {
    final Color color = isSuccess ? AppColors.income : AppColors.expense;

    return Column(
      children: <Widget>[
        Container(
          height: 88,
          width: 88,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSuccess ? Icons.check_rounded : Icons.close_rounded,
            color: color,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isSuccess ? 'Transfer successful' : 'Transfer failed',
          style: AppTypography.headline,
          textAlign: TextAlign.center,
        ),
        if (isSuccess && state.receipt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${CurrencyFormatter.format(state.receipt!.amount)} sent to '
            '${state.receipt!.beneficiary.name}',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});

  final TransferEntity receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          SummaryRow(label: 'Reference', value: receipt.referenceId),
          SummaryRow(label: 'To', value: receipt.beneficiary.name),
          SummaryRow(label: 'Account', value: receipt.beneficiary.accountNumber),
          SummaryRow(
            label: 'Date',
            value: DateFormat('MMM d, y • HH:mm').format(receipt.timestamp),
          ),
          SummaryRow(
            label: 'Remarks',
            value: receipt.remarks.isEmpty ? '—' : receipt.remarks,
          ),
          const Divider(height: AppSpacing.xl),
          SummaryRow(
            label: 'Amount',
            value: CurrencyFormatter.format(receipt.amount),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}
