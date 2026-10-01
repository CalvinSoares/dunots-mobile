import 'dart:convert';
import 'dart:io';

import 'sync_contract.dart';
import 'sync_crypto.dart';

class SyncPairingCode {
  final Uri address;
  final String token;
  final DateTime expiresAt;

  const SyncPairingCode({
    required this.address,
    required this.token,
    required this.expiresAt,
  });

  String encode() => jsonEncode({
    'address': address.toString(),
    'token': token,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  });

  factory SyncPairingCode.decode(String value) {
    Object? decoded;
    try {
      decoded = jsonDecode(value);
    } on FormatException {
      final lines = value
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
      if (lines.length != 2) {
        throw const FormatException('Código de pareamento inválido.');
      }
      decoded = {
        'address': lines[0],
        'token': lines[1],
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 10))
            .toIso8601String(),
      };
    }
    if (decoded is! Map ||
        decoded['address'] is! String ||
        decoded['token'] is! String ||
        decoded['expiresAt'] is! String) {
      throw const FormatException('Código de pareamento inválido.');
    }
    final address = Uri.tryParse(decoded['address'] as String);
    final expiresAt = DateTime.tryParse(decoded['expiresAt'] as String);
    if (address == null ||
        !address.hasScheme ||
        (address.scheme != 'http' && address.scheme != 'https') ||
        (decoded['token'] as String).isEmpty ||
        expiresAt == null) {
      throw const FormatException('Código de pareamento inválido.');
    }
    return SyncPairingCode(
      address: address,
      token: decoded['token'] as String,
      expiresAt: expiresAt,
    );
  }
}

class SyncNetworkSession {
  final HttpClient _client;
  final SyncPackage package;
  final Uri address;
  final String sessionToken;
  final DateTime expiresAt;
  bool _used = false;

  SyncNetworkSession({
    required this._client,
    required this.package,
    required this.address,
    required this.sessionToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Future<void> sendBack(SyncPackage package) async {
    if (_used) {
      throw StateError('A sessão de sincronização já foi usada.');
    }
    if (isExpired) {
      throw StateError('A sessão de sincronização expirou.');
    }
    final payload = await SyncCrypto.encryptPackage(package, sessionToken);
    final request = await _client.postUrl(address.resolve('/dunots-sync'));
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $sessionToken')
      ..contentType = ContentType.text;
    request.write(payload);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.accepted) {
      throw StateError('A sessão de retorno expirou ou já foi usada: $body');
    }
    _used = true;
    _client.close(force: true);
  }
}

class SyncNetworkClient {
  final HttpClient _client;

  SyncNetworkClient({HttpClient? client}) : _client = client ?? HttpClient();

  Future<SyncNetworkSession> receiveFromDesktop(SyncPairingCode pairing) async {
    if (pairing.expiresAt.isBefore(DateTime.now().toUtc())) {
      throw StateError('O código de pareamento expirou.');
    }
    final request = await _client.getUrl(
      pairing.address.resolve('/dunots-sync'),
    );
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${pairing.token}',
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw StateError('O endereço ou token não foi aceito: $body');
    }
    final envelope = jsonDecode(body);
    if (envelope is! Map ||
        envelope['package'] is! String ||
        envelope['sessionToken'] is! String) {
      throw const FormatException('A sessão recebida está incompleta.');
    }
    final package = await SyncCrypto.decryptPackage(
      envelope['package'] as String,
      pairing.token,
    );
    return SyncNetworkSession(
      client: _client,
      package: package,
      address: pairing.address,
      sessionToken: envelope['sessionToken'] as String,
      expiresAt: pairing.expiresAt,
    );
  }

  void close() => _client.close(force: true);
}
