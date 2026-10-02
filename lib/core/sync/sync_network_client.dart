import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'sync_contract.dart';
import 'sync_crypto.dart';

class SyncPairingCode {
  static const format = 'dunots-pairing';
  static const version = 1;

  final Uri address;
  final String token;
  final DateTime expiresAt;

  const SyncPairingCode({
    required this.address,
    required this.token,
    required this.expiresAt,
  });

  String encode() => jsonEncode({
    'format': format,
    'version': version,
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
        (decoded['format'] != null &&
            (decoded['format'] != format || decoded['version'] != version)) ||
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

class SyncNetworkHostInfo {
  final SyncPairingCode pairing;

  const SyncNetworkHostInfo(this.pairing);

  String get address => pairing.address.toString();
  String get token => pairing.token;
  DateTime get expiresAt => pairing.expiresAt;
  String get invite => pairing.encode();
}

/// Host HTTP temporário usado quando o mobile inicia o pareamento.
///
/// O protocolo é o mesmo do host Tauri: GET entrega o pacote e cria uma
/// sessão de retorno; POST aceita o pacote de volta exatamente uma vez.
class SyncNetworkHost {
  HttpServer? _server;
  String? _pairingToken;
  String? _sessionToken;
  bool _pairingConsumed = false;
  DateTime? _expiresAt;
  String? _incomingPayload;
  String? _incomingSecret;
  String? _hostAddress;

  SyncNetworkHostInfo? get info {
    final token = _pairingToken;
    final expiresAt = _expiresAt;
    final server = _server;
    final hostAddress = _hostAddress;
    if (token == null ||
        expiresAt == null ||
        server == null ||
        hostAddress == null) {
      return null;
    }
    return SyncNetworkHostInfo(
      SyncPairingCode(
        address: Uri.parse('http://$hostAddress:${server.port}'),
        token: token,
        expiresAt: expiresAt,
      ),
    );
  }

  Future<SyncNetworkHostInfo> start(
    SyncPackage package, {
    String? token,
    Duration lifetime = const Duration(minutes: 10),
  }) async {
    await stop();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final hostAddress = await _findLocalAddress();
    final pairingToken = token ?? _newToken('pairing');
    _server = server;
    _pairingToken = pairingToken;
    _sessionToken = null;
    _pairingConsumed = false;
    _incomingPayload = null;
    _incomingSecret = null;
    _hostAddress = hostAddress;
    _expiresAt = DateTime.now().toUtc().add(lifetime);

    final encryptedPackage = await SyncCrypto.encryptPackage(
      package,
      pairingToken,
    );
    server.listen(
      (request) => _handleRequest(request, encryptedPackage),
      onError: (_) {},
    );
    Future<void>.delayed(lifetime, stop);
    return info!;
  }

  SyncNetworkIncoming? takeIncoming() {
    final payload = _incomingPayload;
    final secret = _incomingSecret;
    _incomingPayload = null;
    _incomingSecret = null;
    _hostAddress = null;
    if (payload == null || secret == null) return null;
    return SyncNetworkIncoming(payload: payload, secret: secret);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _pairingToken = null;
    _sessionToken = null;
    _expiresAt = null;
    _incomingPayload = null;
    _incomingSecret = null;
    if (server != null) await server.close(force: true);
  }

  Future<void> _handleRequest(
    HttpRequest request,
    String encryptedPackage,
  ) async {
    final response = request.response
      ..headers
          .set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType)
      ..headers.set(HttpHeaders.accessControlAllowOriginHeader, '*')
      ..headers.set(
        HttpHeaders.accessControlAllowHeadersHeader,
        'Authorization, Content-Type',
      )
      ..headers.set(
        HttpHeaders.accessControlAllowMethodsHeader,
        'GET, POST, OPTIONS',
      );
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }
    if (request.uri.path != '/dunots-sync') {
      await _writeJson(response, HttpStatus.notFound, {'error': 'not found'});
      return;
    }
    final providedToken = _bearerToken(request.headers.value('authorization'));
    if (_isExpired) {
      await _writeJson(response, HttpStatus.unauthorized, {
        'error': 'invalid or expired pairing token',
      });
      return;
    }
    if (request.method == 'GET' &&
        providedToken == _pairingToken &&
        !_pairingConsumed) {
      _pairingConsumed = true;
      final sessionToken = _newToken('session');
      _sessionToken = sessionToken;
      await _writeJson(response, HttpStatus.ok, {
        'package': encryptedPackage,
        'sessionToken': sessionToken,
      });
      return;
    }
    if (request.method == 'POST' &&
        providedToken != null &&
        providedToken == _sessionToken) {
      final body = await utf8.decoder.bind(request).join();
      _sessionToken = null;
      _incomingPayload = body;
      _incomingSecret = providedToken;
      await _writeJson(response, HttpStatus.accepted, {'accepted': true});
      return;
    }
    await _writeJson(response, HttpStatus.unauthorized, {
      'error': 'invalid or expired pairing token',
    });
  }

  bool get _isExpired =>
      _expiresAt == null || DateTime.now().toUtc().isAfter(_expiresAt!);

  static String? _bearerToken(String? value) {
    if (value == null) return null;
    const prefix = 'Bearer ';
    return value.startsWith(prefix) ? value.substring(prefix.length) : null;
  }

  static Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, Object> value,
  ) async {
    response.statusCode = statusCode;
    response.write(jsonEncode(value));
    await response.close();
  }

  static Future<String> _findLocalAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final networkInterface in interfaces) {
        for (final address in networkInterface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
    } catch (_) {
      // O fallback permite testes locais e redes que ocultam as interfaces.
    }
    return '127.0.0.1';
  }

  static String _newToken(String prefix) {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return '$prefix-${base64UrlEncode(bytes).replaceAll('=', '')}';
  }
}

class SyncNetworkIncoming {
  final String payload;
  final String secret;

  const SyncNetworkIncoming({required this.payload, required this.secret});
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
