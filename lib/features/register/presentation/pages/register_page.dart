import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/numeric_keypad.dart';
import '../../../../core/widgets/pin_input.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/repositories/register_repository_impl.dart';
import '../../domain/repositories/register_repository.dart';
import '../bloc/register_bloc.dart';

/// Registration wizard: phone/OTP → eKYC → credentials → account activated,
/// driven entirely by [RegisterBloc].
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key, this.repository});

  /// Optional injection point for tests; falls back to the default impl.
  final RegisterRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterBloc>(
      create: (_) => RegisterBloc(
        repository: repository ?? RegisterRepositoryImpl(),
      ),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listenWhen: (RegisterState prev, RegisterState curr) =>
          prev.status != curr.status,
      listener: (BuildContext context, RegisterState state) {
        if (state.status == RegisterStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.expense,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      builder: (BuildContext context, RegisterState state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: SafeArea(
            child: switch (state.step) {
              RegisterStep.phone => _PhoneStep(state: state),
              RegisterStep.otp => _OtpStep(state: state),
              RegisterStep.kyc => _KycStep(state: state),
              RegisterStep.credentials => _CredentialsStep(state: state),
              RegisterStep.success => _SuccessStep(state: state),
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, RegisterState state) {
    switch (state.step) {
      case RegisterStep.success:
        return null;
      case RegisterStep.phone:
        return AppBar(title: const Text('Create account'));
      case RegisterStep.otp:
        return AppBar(
          title: const Text('Verify phone'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.read<RegisterBloc>().add(const RegisterBackRequested()),
          ),
        );
      case RegisterStep.kyc:
        return AppBar(
          title: const Text('Identity verification'),
          automaticallyImplyLeading: false,
        );
      case RegisterStep.credentials:
        return AppBar(
          title: const Text('Account setup'),
          automaticallyImplyLeading: false,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Shared step-progress indicator (4 onboarding stages).
// ---------------------------------------------------------------------------

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});

  final RegisterStep step;

  int get _index => switch (step) {
        RegisterStep.phone => 0,
        RegisterStep.otp => 0,
        RegisterStep.kyc => 1,
        RegisterStep.credentials => 2,
        RegisterStep.success => 3,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(4, (int i) {
        final bool active = i <= _index;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 3 ? 0 : AppSpacing.sm),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1a: Phone entry
// ---------------------------------------------------------------------------

class _PhoneStep extends StatefulWidget {
  const _PhoneStep({required this.state});

  final RegisterState state;

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RegisterBloc bloc = context.read<RegisterBloc>();
    final RegisterState state = widget.state;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.lg,
      ),
      children: <Widget>[
        _StepProgress(step: state.step),
        const SizedBox(height: AppSpacing.xl),
        Text("What's your phone number?", style: AppTypography.headline),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "We'll text you a code to verify it's really you.",
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        CustomTextField(
          label: 'Phone number',
          controller: _controller,
          hintText: '090 123 4567',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
          ],
          onChanged: (String value) =>
              bloc.add(RegisterPhoneChanged(value)),
        ),
        if (state.phoneError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.phoneError!,
            style: AppTypography.caption.copyWith(color: AppColors.expense),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        CustomButton(
          label: 'Send code',
          isLoading: state.isSubmitting,
          onPressed: () => bloc.add(const RegisterOtpRequested()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1b: OTP verification
// ---------------------------------------------------------------------------

class _OtpStep extends StatelessWidget {
  const _OtpStep({required this.state});

  final RegisterState state;

  @override
  Widget build(BuildContext context) {
    final RegisterBloc bloc = context.read<RegisterBloc>();
    final bool hasError = state.otpError != null;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.lg,
      ),
      children: <Widget>[
        _StepProgress(step: state.step),
        const SizedBox(height: AppSpacing.xl),
        Text('Enter verification code', style: AppTypography.headline),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sent to ${state.phoneNumber}. Use 123456 for this demo.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PinInput(
          length: RegisterBloc.otpLength,
          filledCount: state.otpDigits,
          hasError: hasError,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 20,
          child: Center(
            child: state.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(
                    hasError ? state.otpError! : '',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ResendRow(state: state),
        const SizedBox(height: AppSpacing.lg),
        NumericKeypad(
          onDigitPressed: (String digit) =>
              bloc.add(RegisterOtpDigitAdded(digit)),
          onBackspace: () => bloc.add(const RegisterOtpDigitRemoved()),
        ),
      ],
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.state});

  final RegisterState state;

  @override
  Widget build(BuildContext context) {
    final RegisterBloc bloc = context.read<RegisterBloc>();

    if (state.canResendOtp) {
      return Center(
        child: TextButton(
          onPressed: () => bloc.add(const RegisterOtpResendRequested()),
          child: const Text('Resend code'),
        ),
      );
    }
    return Center(
      child: Text(
        'Resend code in ${state.otpSecondsRemaining}s',
        style: AppTypography.caption,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: eKYC
// ---------------------------------------------------------------------------

class _KycStep extends StatelessWidget {
  const _KycStep({required this.state});

  final RegisterState state;

  @override
  Widget build(BuildContext context) {
    final RegisterBloc bloc = context.read<RegisterBloc>();

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.lg,
            ),
            children: <Widget>[
              _StepProgress(step: state.step),
              const SizedBox(height: AppSpacing.xl),
              Text('Verify your identity', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'To keep your account secure, we need a photo of your '
                'National ID (CCCD) and a quick facial scan.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _KycTile(
                icon: Icons.badge_outlined,
                title: 'National ID — Front',
                done: state.idFrontUploaded,
                onTap: () => bloc.add(const RegisterIdFrontUploaded()),
              ),
              const SizedBox(height: AppSpacing.md),
              _KycTile(
                icon: Icons.badge_outlined,
                title: 'National ID — Back',
                done: state.idBackUploaded,
                onTap: () => bloc.add(const RegisterIdBackUploaded()),
              ),
              const SizedBox(height: AppSpacing.md),
              _KycTile(
                icon: Icons.face_retouching_natural_outlined,
                title: 'Facial scan',
                done: state.faceScanned,
                busy: state.isSubmitting && !state.faceScanned,
                onTap: () => bloc.add(const RegisterFaceScanRequested()),
              ),
              if (state.kycError != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  state.kycError!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.expense,
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: CustomButton(
            label: 'Continue',
            // Only reflects the KYC submit, not the facial-scan simulation.
            isLoading: state.isSubmitting && state.isKycComplete,
            onPressed: () => bloc.add(const RegisterKycSubmitted()),
          ),
        ),
      ],
    );
  }
}

/// A single eKYC capture tile with idle / busy / done states.
class _KycTile extends StatelessWidget {
  const _KycTile({
    required this.icon,
    required this.title,
    required this.done,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final bool done;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMd,
        onTap: done || busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: done ? AppColors.income : AppColors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: Text(title, style: AppTypography.bodyStrong)),
              _trailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing() {
    if (busy) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      );
    }
    if (done) {
      return const Icon(Icons.check_circle, color: AppColors.income);
    }
    return const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary);
  }
}

// ---------------------------------------------------------------------------
// Step 3: Credentials setup
// ---------------------------------------------------------------------------

class _CredentialsStep extends StatefulWidget {
  const _CredentialsStep({required this.state});

  final RegisterState state;

  @override
  State<_CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends State<_CredentialsStep> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _pin = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<RegisterBloc>().add(
          RegisterCredentialsSubmitted(
            username: _username.text.trim(),
            password: _password.text,
            pin: _pin.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        children: <Widget>[
          _StepProgress(step: widget.state.step),
          const SizedBox(height: AppSpacing.xl),
          Text('Secure your account', style: AppTypography.headline),
          const SizedBox(height: AppSpacing.xl),
          CustomTextField(
            label: 'Username',
            controller: _username,
            hintText: 'Choose a username',
            prefixIcon: Icons.person_outline,
            validator: (String? v) {
              final String value = (v ?? '').trim();
              if (value.isEmpty) return 'Username is required';
              if (value.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField.password(
            label: 'Password',
            controller: _password,
            hintText: 'At least 8 characters',
            validator: (String? v) {
              final String value = v ?? '';
              if (value.isEmpty) return 'Password is required';
              if (value.length < 8) return 'At least 8 characters';
              if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                  !RegExp(r'[0-9]').hasMatch(value)) {
                return 'Use both letters and numbers';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField.password(
            label: 'Confirm password',
            controller: _confirm,
            hintText: 'Re-enter your password',
            validator: (String? v) =>
                v != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField.pin(
            label: 'Transaction PIN (6 digits)',
            controller: _pin,
            hintText: '••••••',
            validator: (String? v) =>
                (v ?? '').length != 6 ? 'PIN must be 6 digits' : null,
          ),
          const SizedBox(height: AppSpacing.xxl),
          CustomButton(
            label: 'Create account',
            isLoading: widget.state.isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Success
// ---------------------------------------------------------------------------

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({required this.state});

  final RegisterState state;

  @override
  Widget build(BuildContext context) {
    final account = state.account;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.xxl,
            ),
            children: <Widget>[
              Center(
                child: Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppColors.income,
                    size: 54,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Account activated!',
                style: AppTypography.headline,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Congratulations — your NovaBank account is ready to use.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (account != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.cardGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppSpacing.borderRadiusLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'YOUR ACCOUNT NUMBER',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.75),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        account.accountNumber,
                        style: AppTypography.headline.copyWith(
                          color: AppColors.textOnPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '@${account.username}',
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: CustomButton(
            label: 'Continue to login',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (Route<void> route) => false,
            ),
          ),
        ),
      ],
    );
  }
}
