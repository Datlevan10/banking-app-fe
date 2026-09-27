import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/numeric_keypad.dart';
import '../../../../core/widgets/pin_input.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../data/auth_repository_factory.dart';
import '../bloc/auth_bloc.dart';

/// Login screen: PIN + biometric sign-in with a username/password fallback.
///
/// Creates the [AuthBloc] and immediately probes biometric availability; the
/// rendering is delegated to [_LoginView].
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(repository: createAuthRepository())
        ..add(const AuthBiometricAvailabilityRequested()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Navigate on success; surface failures as a snackbar.
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState prev, AuthState curr) =>
              prev.status != curr.status,
          listener: _onStatusChanged,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (BuildContext context, AuthState state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _Header(),
                    const SizedBox(height: AppSpacing.xxl),
                    if (state.mode == AuthMode.pin)
                      _PinSection(state: state)
                    else
                      const _CredentialsSection(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onStatusChanged(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomePage()),
      );
    } else if (state.status == AuthStatus.failure &&
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
  }
}

/// Brand header shown at the top of the login screen.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: AppColors.textOnPrimary,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Welcome back',
          style: AppTypography.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to continue',
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// PIN entry: dots + secure keypad + biometric shortcut.
class _PinSection extends StatelessWidget {
  const _PinSection({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final AuthBloc bloc = context.read<AuthBloc>();
    final bool hasError = state.status == AuthStatus.failure;

    return Column(
      children: <Widget>[
        Text('Enter your PIN', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xl),
        PinInput(
          length: AuthBloc.pinLength,
          filledCount: state.enteredDigits,
          hasError: hasError,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Reserve vertical space so the layout doesn't jump on error.
        SizedBox(
          height: 20,
          child: state.status == AuthStatus.authenticating
              ? const _InlineLoader()
              : Text(
                  hasError ? (state.errorMessage ?? '') : '',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.expense,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        NumericKeypad(
          showBiometric: state.isBiometricAvailable,
          onDigitPressed: (String digit) =>
              bloc.add(AuthPinDigitAdded(digit)),
          onBackspace: () => bloc.add(const AuthPinDigitRemoved()),
          onBiometricPressed: () => bloc.add(const AuthBiometricRequested()),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextButton(
          onPressed: () => bloc.add(const AuthModeToggled()),
          child: const Text('Sign in with password instead'),
        ),
      ],
    );
  }
}

/// Standard username + password sign-in form.
///
/// Stateful because it owns the [TextEditingController]s; all validation and
/// auth still happen in the [AuthBloc].
class _CredentialsSection extends StatefulWidget {
  const _CredentialsSection();

  @override
  State<_CredentialsSection> createState() => _CredentialsSectionState();
}

class _CredentialsSectionState extends State<_CredentialsSection> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          AuthCredentialsSubmitted(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final AuthBloc bloc = context.read<AuthBloc>();
    final bool isLoading =
        context.select((AuthBloc b) => b.state.status) ==
            AuthStatus.authenticating;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CustomTextField(
            label: 'Username',
            controller: _usernameController,
            hintText: 'Enter your username',
            prefixIcon: Icons.person_outline,
            validator: (String? value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Username is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomTextField.password(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Enter your password',
            validator: (String? value) =>
                (value == null || value.isEmpty)
                    ? 'Password is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          CustomButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: () => _submit(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: () => bloc.add(const AuthModeToggled()),
            child: const Text('Sign in with PIN instead'),
          ),
        ],
      ),
    );
  }
}

/// Small inline spinner shown while authenticating.
class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2.2),
    );
  }
}
