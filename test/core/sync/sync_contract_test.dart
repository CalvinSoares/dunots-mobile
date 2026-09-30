import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/sync/sync_contract.dart';

void main() {
  test('serializa todas as coleções do contrato v1', () {
    final package = SyncPackage(
      exportedAt: DateTime.utc(2026, 9, 30),
      source: const SyncIdentity(deviceId: 'mobile-1', deviceName: 'Celular'),
      collections: {
        SyncCollections.flashcards: [
          SyncRecord({'id': 'card-1', 'question': 'O que é uma VLAN?'}),
        ],
      },
    );

    final decoded = SyncPackage.fromJson(package.toJson());

    expect(decoded.source.deviceId, 'mobile-1');
    expect(decoded.recordsFor(SyncCollections.flashcards), hasLength(1));
    expect(decoded.recordsFor(SyncCollections.flashcards).single.id, 'card-1');
    expect(
      decoded.toJson()['collections'],
      containsPair(SyncCollections.quizQuestions, []),
    );
  });

  test('rejeita pacote de outro formato ou versão', () {
    expect(
      () => SyncPackage.fromJson({'format': 'outro-formato', 'version': 1}),
      throwsFormatException,
    );
  });

  test('ignora registros sem id para manter compatibilidade com o desktop', () {
    final package = SyncPackage.fromJson({
      'format': 'dunots-sync',
      'version': 1,
      'exportedAt': '2026-09-30T00:00:00.000Z',
      'source': {'deviceId': 'desktop-1', 'deviceName': 'Notebook'},
      'collections': {
        'flashcards': [
          {'question': 'sem id'},
          {'id': 'card-1', 'question': 'válido'},
        ],
      },
    });

    expect(package.recordsFor(SyncCollections.flashcards), hasLength(1));
    expect(package.recordsFor(SyncCollections.flashcards).single.id, 'card-1');
  });
}
