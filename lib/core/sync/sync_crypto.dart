import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'sync_contract.dart';

/// Implementa o envelope AES-GCM usado pelo desktop/Tauri.
///
/// O segredo nunca é enviado no corpo: ele é usado para derivar uma chave
/// SHA-256 e o envelope carrega somente IV e ciphertext+tag em base64.
class SyncCrypto {
  static final _algorithm = AesGcm.with256bits();
  static final _hash = Sha256();

  static Future<SecretKey> _deriveKey(String secret) async {
    final digest = await _hash.hash(utf8.encode(secret));
    return SecretKey(digest.bytes);
  }

  static Future<String> encryptPackage(
    SyncPackage package,
    String secret, {
    List<int>? nonce,
  }) async {
    final iv = nonce ?? _algorithm.newNonce();
    if (iv.length != 12) {
      throw ArgumentError.value(nonce, 'nonce', 'deve ter 12 bytes');
    }
    final box = await _algorithm.encrypt(
      utf8.encode(jsonEncode(package.toJson())),
      secretKey: await _deriveKey(secret),
      nonce: iv,
    );
    final encrypted = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
    return jsonEncode({
      'format': 'dunots-sync-encrypted',
      'version': 1,
      'iv': base64Encode(iv),
      'data': base64Encode(encrypted),
    });
  }

  static Future<SyncPackage> decryptPackage(
    String payload,
    String secret,
  ) async {
    final value = jsonDecode(payload);
    if (value is! Map ||
        value['format'] != 'dunots-sync-encrypted' ||
        value['version'] != 1 ||
        value['iv'] is! String ||
        value['data'] is! String) {
      throw const FormatException(
        'O transporte não contém um pacote criptografado válido.',
      );
    }
    final iv = base64Decode(value['iv'] as String);
    final encrypted = base64Decode(value['data'] as String);
    if (iv.length != 12 || encrypted.length < 16) {
      throw const FormatException('O envelope criptografado está incompleto.');
    }
    final split = encrypted.length - 16;
    final box = SecretBox(
      encrypted.sublist(0, split),
      nonce: iv,
      mac: Mac(encrypted.sublist(split)),
    );
    try {
      final clear = await _algorithm.decrypt(
        box,
        secretKey: await _deriveKey(secret),
      );
      final decoded = jsonDecode(utf8.decode(clear));
      return SyncPackage.fromJson(decoded);
    } catch (error) {
      throw FormatException(
        'Não foi possível descriptografar o pacote: $error',
      );
    }
  }
}
