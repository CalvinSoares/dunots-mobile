import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/sync/sync_contract.dart';
import 'package:dunots_mobile/core/sync/sync_crypto.dart';

void main() {
  test(
    'encripta e descriptografa o envelope compatível com AES-GCM do desktop',
    () async {
      final package = SyncPackage.empty(
        exportedAt: DateTime.utc(2026, 10, 1),
        source: const SyncIdentity(
          deviceId: 'mobile-test',
          deviceName: 'Mobile',
        ),
      );
      final encrypted = await SyncCrypto.encryptPackage(
        package,
        'pairing-token',
        nonce: List<int>.filled(12, 7),
      );
      final decrypted = await SyncCrypto.decryptPackage(
        encrypted,
        'pairing-token',
      );

      expect(decrypted.source.deviceId, 'mobile-test');
      expect(decrypted.exportedAt, package.exportedAt);
      expect(encrypted, contains('dunots-sync-encrypted'));
    },
  );

  test('rejeita segredo incorreto', () async {
    final package = SyncPackage.empty(
      exportedAt: DateTime.utc(2026, 10, 1),
      source: const SyncIdentity(deviceId: 'mobile-test', deviceName: 'Mobile'),
    );
    final encrypted = await SyncCrypto.encryptPackage(package, 'correto');

    expect(
      () => SyncCrypto.decryptPackage(encrypted, 'incorreto'),
      throwsA(isA<FormatException>()),
    );
  });

  test('descriptografa vetor produzido pelo WebCrypto do desktop', () async {
    final payload = await File('test/fixtures/desktop_webcrypto_envelope.json')
        .readAsString();
    final package = await SyncCrypto.decryptPackage(payload, 'pairing-token');

    expect(package.source.deviceId, 'mobile-test');
    expect(package.source.deviceName, 'Mobile');
    expect(package.exportedAt, DateTime.utc(2026, 10, 1));
  });

  test('produz exatamente o envelope esperado pelo WebCrypto', () async {
    final package = SyncPackage.empty(
      exportedAt: DateTime.utc(2026, 10, 1),
      source: const SyncIdentity(deviceId: 'mobile-test', deviceName: 'Mobile'),
    );
    final actual = jsonDecode(
      await SyncCrypto.encryptPackage(
        package,
        'pairing-token',
        nonce: List<int>.filled(12, 7),
      ),
    );
    final expected = jsonDecode(
      await File('test/fixtures/desktop_webcrypto_envelope.json')
          .readAsString(),
    );

    expect(actual, expected);
  });
}
