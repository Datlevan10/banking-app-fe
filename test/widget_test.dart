// Widget smoke tests for the banking app (dashboard + login + transfer flows).

import 'dart:math';

import 'package:banking_app_fe/core/theme/app_theme.dart';
import 'package:banking_app_fe/features/auth/presentation/pages/login_page.dart';
import 'package:banking_app_fe/features/home/presentation/pages/home_page.dart';
import 'package:banking_app_fe/features/onboarding/presentation/pages/splash_page.dart';
import 'package:banking_app_fe/features/qr_scan/data/repositories/qr_scan_repository_impl.dart';
import 'package:banking_app_fe/features/qr_scan/presentation/pages/qr_scan_page.dart';
import 'package:banking_app_fe/features/register/data/repositories/register_repository_impl.dart';
import 'package:banking_app_fe/features/register/presentation/pages/register_page.dart';
import 'package:banking_app_fe/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:banking_app_fe/features/transfer/presentation/pages/transfer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a page in the real app theme so tests exercise production styling.
Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

/// Taps the on-screen keypad digits in order.
Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final String digit in pin.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
}

/// Pumps the login page on a tall surface so the full keypad and the mode
/// toggle are on-screen (the default 800x600 test window clips them).
Future<void> _pumpLogin(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(500, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_wrap(const LoginPage()));
  await tester.pumpAndSettle();
}

/// Pumps the transfer page with a deterministic repository (no random failure)
/// on a tall surface, and waits for beneficiaries/balance to load.
Future<void> _pumpTransfer(
  WidgetTester tester, {
  required double failureRate,
}) async {
  await tester.binding.setSurfaceSize(const Size(500, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_wrap(
    TransferPage(
      repository: TransferRepositoryImpl(
        random: Random(0),
        failureRate: failureRate,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Selects the first beneficiary and enters an amount on the input step.
Future<void> _fillTransfer(WidgetTester tester, String amount) async {
  await tester.tap(find.text('John'));
  await tester.pump();
  await tester.enterText(find.byType(TextField).first, amount);
  await tester.pump();
}

void main() {
  group('HomePage', () {
    testWidgets('loads and renders balance card + transactions',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));

      // Initially loading its (fake) data.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // Balance hidden by default -> masked dots show.
      expect(find.textContaining('•'), findsWidgets);
      expect(find.text('Recent transactions'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('QR Scan'), findsOneWidget);
    });

    testWidgets('visibility toggle reveals the balance',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.textContaining(r'$12,480.75'), findsNothing);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pumpAndSettle();
      expect(find.textContaining(r'$12,480.75'), findsOneWidget);
    });
  });

  group('LoginPage', () {
    testWidgets('shows PIN entry by default and can switch to password',
        (WidgetTester tester) async {
      await _pumpLogin(tester);

      expect(find.text('Enter your PIN'), findsOneWidget);

      await tester.tap(find.text('Sign in with password instead'));
      await tester.pumpAndSettle();

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('correct PIN navigates to the dashboard',
        (WidgetTester tester) async {
      await _pumpLogin(tester);

      await _enterPin(tester, '123456');
      await tester.pumpAndSettle();

      // Landed on the dashboard.
      expect(find.text('Recent transactions'), findsOneWidget);
    });

    testWidgets('wrong PIN surfaces an error and stays on login',
        (WidgetTester tester) async {
      await _pumpLogin(tester);

      await _enterPin(tester, '000000');
      await tester.pumpAndSettle();

      expect(find.textContaining('Incorrect PIN'), findsWidgets);
      expect(find.text('Enter your PIN'), findsOneWidget);
    });
  });

  group('TransferPage', () {
    testWidgets('happy path: input -> confirm -> success receipt',
        (WidgetTester tester) async {
      await _pumpTransfer(tester, failureRate: 0);

      await _fillTransfer(tester, '100');
      await tester.tap(find.text('Review transfer'));
      await tester.pumpAndSettle();

      // Confirmation step.
      expect(find.text('Confirm & send'), findsOneWidget);
      await tester.tap(find.text('Confirm & send'));
      await tester.pumpAndSettle();

      // Success receipt.
      expect(find.text('Transfer successful'), findsOneWidget);
      expect(find.textContaining('TXN-'), findsOneWidget);
    });

    testWidgets('blocks review when amount exceeds balance',
        (WidgetTester tester) async {
      await _pumpTransfer(tester, failureRate: 0);

      await _fillTransfer(tester, '99999999');
      await tester.tap(find.text('Review transfer'));
      await tester.pumpAndSettle();

      expect(find.text('Amount exceeds available balance'), findsOneWidget);
      // Still on the input step.
      expect(find.text('Confirm & send'), findsNothing);
    });

    testWidgets('requires a beneficiary before review',
        (WidgetTester tester) async {
      await _pumpTransfer(tester, failureRate: 0);

      // Enter an amount but do not pick a beneficiary.
      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pump();
      await tester.tap(find.text('Review transfer'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a beneficiary'), findsOneWidget);
    });

    testWidgets('failed transfer shows the failure screen',
        (WidgetTester tester) async {
      await _pumpTransfer(tester, failureRate: 1);

      await _fillTransfer(tester, '100');
      await tester.tap(find.text('Review transfer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & send'));
      await tester.pumpAndSettle();

      expect(find.text('Transfer failed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('Onboarding', () {
    testWidgets('splash navigates to the gateway after init',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SplashPage()));

      expect(find.text('NovaBank'), findsOneWidget); // splash branding
      await tester.pump(SplashPage.initDuration);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to NovaBank'), findsOneWidget);
      expect(find.text('Open an account'), findsOneWidget);
    });
  });

  group('RegisterPage', () {
    testWidgets('completes the full onboarding wizard to activation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(
        RegisterPage(repository: RegisterRepositoryImpl(random: Random(0))),
      ));
      await tester.pumpAndSettle();

      // Step 1a: phone.
      await tester.enterText(find.byType(TextField).first, '0901234567');
      await tester.pump();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      // Step 1b: OTP (demo code 123456).
      expect(find.text('Enter verification code'), findsOneWidget);
      for (final String digit in '123456'.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Step 2: eKYC.
      expect(find.text('Verify your identity'), findsOneWidget);
      await tester.tap(find.text('National ID — Front'));
      await tester.pump();
      await tester.tap(find.text('National ID — Back'));
      await tester.pump();
      await tester.tap(find.text('Facial scan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: credentials.
      expect(find.text('Secure your account'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'johndoe');
      await tester.enterText(find.byType(TextField).at(1), 'password1');
      await tester.enterText(find.byType(TextField).at(2), 'password1');
      await tester.enterText(find.byType(TextField).at(3), '123456');
      await tester.pump();
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      // Step 4: activated.
      expect(find.text('Account activated!'), findsOneWidget);
      expect(find.text('Continue to login'), findsOneWidget);
    });

    testWidgets('wrong OTP shows an inline error and stays on the OTP step',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(
        RegisterPage(repository: RegisterRepositoryImpl(random: Random(0))),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '0901234567');
      await tester.pump();
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      for (final String digit in '000000'.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.textContaining('incorrect'), findsWidgets);
      expect(find.text('Enter verification code'), findsOneWidget);
    });
  });

  group('QrScanPage', () {
    testWidgets('successful scan routes to a pre-filled transfer',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(500, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(
        QrScanPage(
          repository: QrScanRepositoryImpl(
            scanDuration: const Duration(milliseconds: 20),
          ),
        ),
      ));

      // Drive with explicit pumps (the scanner has a repeating animation).
      await tester.pump(); // start scan
      await tester.pump(const Duration(milliseconds: 300)); // permission + scan
      await tester.pump(); // listener navigates
      await tester.pump(const Duration(seconds: 1)); // transfer prefill loads
      await tester.pump(const Duration(seconds: 1));

      // Landed on the transfer input step, pre-filled from the scanned code.
      expect(find.text('Review transfer'), findsOneWidget);
      expect(find.text('NGUYEN'), findsOneWidget); // beneficiary avatar label
      expect(find.text('500'), findsWidgets); // pre-filled amount

      // Tear down the tree to dispose animations cleanly.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('permission denied shows an error with retry',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(
        QrScanPage(
          repository: QrScanRepositoryImpl(
            permissionGranted: false,
            scanDuration: const Duration(milliseconds: 20),
          ),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Camera access'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
