import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../transfer/presentation/models/transfer_prefill.dart';
import '../../../transfer/presentation/pages/transfer_page.dart';
import '../../data/repositories/qr_scan_repository_impl.dart';
import '../../domain/entities/qr_code_entity.dart';
import '../../domain/repositories/qr_scan_repository.dart';
import '../bloc/qr_scan_bloc.dart';
import '../widgets/scanner_overlay.dart';

/// Full-screen QR scanner. On a successful parse it routes straight to the
/// transfer screen, pre-filled with the scanned beneficiary and amount.
class QrScanPage extends StatelessWidget {
  const QrScanPage({super.key, this.repository});

  /// Optional injection point for tests; falls back to the default impl.
  final QrScanRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QrScanBloc>(
      create: (_) => QrScanBloc(
        repository: repository ?? QrScanRepositoryImpl(),
      )..add(const QrScanStarted()),
      child: const _QrScanView(),
    );
  }
}

class _QrScanView extends StatelessWidget {
  const _QrScanView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<QrScanBloc, QrScanState>(
      listenWhen: (QrScanState prev, QrScanState curr) =>
          prev.status != curr.status,
      listener: (BuildContext context, QrScanState state) {
        if (state.status == QrScanStatus.success && state.result != null) {
          _goToTransfer(context, state.result!);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textOnPrimary,
          title: const Text('Scan to pay'),
        ),
        body: const _ScannerBody(),
      ),
    );
  }

  void _goToTransfer(BuildContext context, QrCodeEntity qr) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TransferPage(
          prefill: TransferPrefill(
            recipientName: qr.recipientName,
            accountNumber: qr.accountNumber,
            bankName: qr.bankName,
            amount: qr.amount,
            remarks: qr.remarks,
          ),
        ),
      ),
    );
  }
}

class _ScannerBody extends StatelessWidget {
  const _ScannerBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QrScanBloc, QrScanState>(
      builder: (BuildContext context, QrScanState state) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Simulated camera preview.
            _CameraPreview(torchOn: state.torchOn),
            const ScannerOverlay(),
            if (state.status == QrScanStatus.failure)
              _ErrorOverlay(message: state.errorMessage ?? 'Scan failed.')
            else
              _BottomControls(state: state),
          ],
        );
      },
    );
  }
}

/// Placeholder for the live camera feed (a real build would host the camera
/// preview widget here). Brightens slightly when the torch is on.
class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.torchOn});

  final bool torchOn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: <Color>[Color(0xFF2A2E38), Color(0xFF0B0D12)],
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: torchOn ? 0.18 : 0.06,
        child: const Center(
          child: Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.white),
        ),
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.state});

  final QrScanState state;

  @override
  Widget build(BuildContext context) {
    final QrScanBloc bloc = context.read<QrScanBloc>();
    final bool detecting = state.status == QrScanStatus.processing;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Torch toggle.
              _TorchButton(
                on: state.torchOn,
                onTap: () => bloc.add(const QrTorchToggled()),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (detecting)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Detecting code…',
                      style: AppTypography.body.copyWith(color: Colors.white),
                    ),
                  ],
                )
              else
                Text(
                  'Align the QR code within the frame',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Icon(
          on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

/// Dark, centred error card with retry / cancel.
class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final QrScanBloc bloc = context.read<QrScanBloc>();

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xl),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.expense,
                size: 44,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.xl),
              CustomButton(
                label: 'Try again',
                onPressed: () => bloc.add(const QrScanRetryRequested()),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                label: 'Cancel',
                variant: ButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
