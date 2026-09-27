// Unit tests for the QR payload parser (EMVCo/VietQR + delimited fallback).

import 'package:banking_app_fe/features/qr_scan/data/repositories/qr_scan_repository_impl.dart';
import 'package:banking_app_fe/features/qr_scan/domain/entities/qr_code_entity.dart';
import 'package:banking_app_fe/features/qr_scan/domain/failures/qr_scan_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final QrScanRepositoryImpl repo = QrScanRepositoryImpl();

  test('parses the default mock VietQR payload', () async {
    final String payload = await repo.captureQr();
    final QrCodeEntity qr = repo.parsePayload(payload);

    expect(qr.bankName, 'Vietcombank');
    expect(qr.accountNumber, '1012345678');
    expect(qr.recipientName, 'NGUYEN VAN A');
    expect(qr.amount, 500);
    expect(qr.remarks, 'Invoice 123');
  });

  test('parses a delimited bank payload', () {
    final QrCodeEntity qr = repo.parsePayload(
      'bank=Techcombank;account=99887766;name=TRAN THI B;amount=250;remark=Rent',
    );

    expect(qr.bankName, 'Techcombank');
    expect(qr.accountNumber, '99887766');
    expect(qr.recipientName, 'TRAN THI B');
    expect(qr.amount, 250);
    expect(qr.remarks, 'Rent');
  });

  test('throws invalidFormat for unrecognised data', () {
    expect(
      () => repo.parsePayload('just some random text'),
      throwsA(isA<QrScanFailure>()),
    );
  });
}
