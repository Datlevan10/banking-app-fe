import '../../domain/entities/qr_code_entity.dart';
import '../../domain/failures/qr_scan_failure.dart';
import '../../domain/repositories/qr_scan_repository.dart';

/// [QrScanRepository] that simulates a camera and parses either an EMVCo /
/// VietQR TLV payload or a simple delimited bank payload.
///
/// The mock camera, permission result and scan latency are injectable so the
/// UI can be exercised on a simulator and in tests deterministically.
class QrScanRepositoryImpl implements QrScanRepository {
  // Initializing formals: the private fields are set directly; callers still
  // pass the public names (`permissionGranted`, `scanDuration`, `mockPayload`).
  QrScanRepositoryImpl({
    this._permissionGranted = true,
    this._scanDuration = const Duration(seconds: 2),
    this._mockPayload,
  });

  // Injectable knobs for the mock camera.
  final bool _permissionGranted;
  final Duration _scanDuration;
  final String? _mockPayload;

  /// VietQR acquirer BIN → bank display name.
  static const Map<String, String> _binToBank = <String, String>{
    '970436': 'Vietcombank',
    '970415': 'VietinBank',
    '970418': 'BIDV',
    '970422': 'MB Bank',
    '970407': 'Techcombank',
    '970416': 'ACB',
  };

  @override
  Future<bool> requestCameraPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _permissionGranted;
  }

  @override
  Future<String> captureQr() async {
    await Future<void>.delayed(_scanDuration);
    // A real implementation would return the first decoded barcode from the
    // camera stream. Here we emit a valid VietQR payload by default.
    return _mockPayload ?? _defaultVietQr();
  }

  @override
  QrCodeEntity parsePayload(String raw) {
    final String data = raw.trim();
    if (data.isEmpty) throw QrScanFailure.invalidFormat;

    // EMVCo/VietQR payloads start with the payload-format indicator "0002".
    if (data.startsWith('0002')) return _parseEmvco(data);

    // Otherwise fall back to a simple `key=value;` bank payload.
    if (data.contains('=')) return _parseDelimited(data);

    throw QrScanFailure.invalidFormat;
  }

  // --- EMVCo / VietQR ------------------------------------------------------

  QrCodeEntity _parseEmvco(String data) {
    final Map<String, String> root = _parseTlv(data);

    // Tag 38 holds the merchant account information (nested TLV).
    final String? merchant = root['38'];
    if (merchant == null) throw QrScanFailure.invalidFormat;
    final Map<String, String> merchantTlv = _parseTlv(merchant);

    // Sub-tag 01 nests the beneficiary: 00 = acquirer BIN, 01 = account number.
    final Map<String, String> beneficiary =
        _parseTlv(merchantTlv['01'] ?? '');
    final String? bin = beneficiary['00'];
    final String? account = beneficiary['01'];
    if (account == null || account.isEmpty) throw QrScanFailure.invalidFormat;

    final String recipient = root['59']?.trim() ?? 'Unknown recipient';
    final double? amount = double.tryParse(root['54'] ?? '');

    // Tag 62 (additional data) sub-tag 08 carries the purpose/remark.
    final Map<String, String> additional =
        root['62'] != null ? _parseTlv(root['62']!) : const <String, String>{};

    return QrCodeEntity(
      bankName: _binToBank[bin] ?? 'Unknown bank',
      accountNumber: account,
      recipientName: recipient,
      amount: amount,
      remarks: additional['08']?.trim() ?? '',
    );
  }

  /// Parses a flat TLV string: each field is tag(2) + length(2) + value(length).
  Map<String, String> _parseTlv(String s) {
    final Map<String, String> map = <String, String>{};
    int i = 0;
    while (i + 4 <= s.length) {
      final String tag = s.substring(i, i + 2);
      final int? length = int.tryParse(s.substring(i + 2, i + 4));
      if (length == null) break;
      final int start = i + 4;
      final int end = start + length;
      if (end > s.length) break;
      map[tag] = s.substring(start, end);
      i = end;
    }
    return map;
  }

  // --- Delimited fallback --------------------------------------------------

  QrCodeEntity _parseDelimited(String data) {
    final Map<String, String> fields = <String, String>{};
    for (final String pair in data.split(';')) {
      final int eq = pair.indexOf('=');
      if (eq <= 0) continue;
      fields[pair.substring(0, eq).trim().toLowerCase()] =
          pair.substring(eq + 1).trim();
    }

    final String? account = fields['account'];
    final String? name = fields['name'];
    if (account == null || account.isEmpty || name == null || name.isEmpty) {
      throw QrScanFailure.invalidFormat;
    }

    return QrCodeEntity(
      bankName: fields['bank'] ?? 'Unknown bank',
      accountNumber: account,
      recipientName: name,
      amount: double.tryParse(fields['amount'] ?? ''),
      remarks: fields['remark'] ?? '',
    );
  }

  // --- Mock payload builder ------------------------------------------------

  /// Builds a valid, CRC-checked VietQR payload for the default mock scan.
  String _defaultVietQr() {
    final String beneficiary = _tlv('00', '970436') + _tlv('01', '1012345678');
    final String merchant = _tlv('00', 'A000000727') +
        _tlv('01', beneficiary) +
        _tlv('02', 'QRIBFTTA');

    final String body = _tlv('00', '01') + // payload format indicator
        _tlv('01', '12') + // dynamic QR
        _tlv('38', merchant) +
        _tlv('53', '704') + // currency (VND placeholder)
        _tlv('54', '500') + // amount
        _tlv('58', 'VN') +
        _tlv('59', 'NGUYEN VAN A') +
        _tlv('62', _tlv('08', 'Invoice 123'));

    // CRC (tag 63, length 04) is computed over the body plus "6304".
    final String toHash = '${body}6304';
    return '$toHash${_crc16(toHash)}';
  }

  String _tlv(String tag, String value) =>
      '$tag${value.length.toString().padLeft(2, '0')}$value';

  /// CRC-16/CCITT-FALSE, as required by the EMVCo QR spec.
  String _crc16(String input) {
    int crc = 0xFFFF;
    for (final int code in input.codeUnits) {
      crc ^= code << 8;
      for (int i = 0; i < 8; i++) {
        crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
