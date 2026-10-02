import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/sync/sync_contract.dart';
import 'package:dunots_mobile/core/sync/sync_crypto.dart';
import 'package:dunots_mobile/core/sync/sync_network_client.dart';

void main() {
  test(
    'faz pareamento local, recebe pacote e envia retorno uma única vez',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final pairingToken = 'pairing-token';
      final sessionToken = 'session-token';
      final package = SyncPackage.empty(
        exportedAt: DateTime.utc(2026, 10, 1),
        source: const SyncIdentity(
          deviceId: 'desktop-test',
          deviceName: 'Desktop',
        ),
      );
      final encrypted = await SyncCrypto.encryptPackage(package, pairingToken);
      var getCount = 0;
      var postCount = 0;
      final subscription = server.listen((request) async {
        final authorization = request.headers.value(
          HttpHeaders.authorizationHeader,
        );
        if (request.method == 'GET' &&
            authorization == 'Bearer $pairingToken' &&
            getCount == 0) {
          getCount++;
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({'package': encrypted, 'sessionToken': sessionToken}),
            );
          await request.response.close();
          return;
        }
        if (request.method == 'POST' &&
            authorization == 'Bearer $sessionToken' &&
            postCount == 0) {
          postCount++;
          request.response
            ..statusCode = HttpStatus.accepted
            ..headers.contentType = ContentType.json
            ..write('{"accepted":true}');
          await request.response.close();
          return;
        }
        request.response
          ..statusCode = HttpStatus.unauthorized
          ..write('{"error":"invalid"}');
        await request.response.close();
      });

      final code = SyncPairingCode(
        address: Uri.parse('http://127.0.0.1:${server.port}'),
        token: pairingToken,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      );
      final client = SyncNetworkClient();
      final session = await client.receiveFromDesktop(code);
      expect(session.package.source.deviceId, 'desktop-test');
      expect(getCount, 1);

      final secondClient = SyncNetworkClient();
      expect(
        () => secondClient.receiveFromDesktop(code),
        throwsA(isA<StateError>()),
      );
      secondClient.close();

      await session.sendBack(
        SyncPackage.empty(
          exportedAt: DateTime.utc(2026, 10, 1),
          source: const SyncIdentity(
            deviceId: 'mobile-test',
            deviceName: 'Mobile',
          ),
        ),
      );
      expect(postCount, 1);
      expect(() => session.sendBack(package), throwsA(isA<StateError>()));

      client.close();
      await subscription.cancel();
      await server.close();
    },
  );

  test(
    'rejeita código de pareamento expirado antes de abrir conexão',
    () async {
      final client = SyncNetworkClient();
      final code = SyncPairingCode(
        address: Uri.parse('http://127.0.0.1:1'),
        token: 'token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
      );

      expect(() => client.receiveFromDesktop(code), throwsA(isA<StateError>()));
      client.close();
    },
  );

  test('lê o convite antigo de duas linhas do desktop', () {
    final code = SyncPairingCode.decode('http://127.0.0.1:43127\nlegacy-token');

    expect(code.address.host, '127.0.0.1');
    expect(code.token, 'legacy-token');
    expect(code.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
  });

  test('codifica e lê o convite QR no contrato compartilhado', () {
    final code = SyncPairingCode(
      address: Uri.parse('http://192.168.0.20:43127'),
      token: 'pairing-qr-token',
      expiresAt: DateTime.utc(2026, 10, 1, 12),
    );

    final decoded = SyncPairingCode.decode(code.encode());

    expect(decoded.address, code.address);
    expect(decoded.token, code.token);
    expect(decoded.expiresAt, code.expiresAt);
  });

  test('host mobile entrega o pacote e aceita o retorno uma única vez', () async {
    final host = SyncNetworkHost();
    final package = SyncPackage.empty(
      exportedAt: DateTime.utc(2026, 10, 1),
      source: const SyncIdentity(
        deviceId: 'mobile-test',
        deviceName: 'Mobile',
      ),
    );
    final info = await host.start(package, token: 'mobile-pairing-token');
    final client = SyncNetworkClient();

    final session = await client.receiveFromDesktop(info.pairing);
    expect(session.package.source.deviceId, 'mobile-test');

    await session.sendBack(
      SyncPackage.empty(
        exportedAt: DateTime.utc(2026, 10, 1),
        source: const SyncIdentity(
          deviceId: 'desktop-test',
          deviceName: 'Desktop',
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    final incoming = host.takeIncoming();
    expect(incoming, isNotNull);
    final returned = await SyncCrypto.decryptPackage(
      incoming!.payload,
      incoming.secret,
    );
    expect(returned.source.deviceId, 'desktop-test');
    expect(host.takeIncoming(), isNull);

    client.close();
    await host.stop();
  });
}
