import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';

void main() {
  test('cria um flashcard com os dados informados', () {
    final createdAt = DateTime(2026, 9, 27);

    final card = Flashcard(
      id: 'card-001',
      front: 'O que é TCP?',
      back: 'Um protocolo de transporte.',
      createdAt: createdAt,
    );

    expect(card.id, 'card-001');
    expect(card.front, 'O que é TCP?');
    expect(card.back, 'Um protocolo de transporte.');
    expect(card.createdAt, createdAt);
  });

  test('cria uma cópia alterando somente o campo informado', () {
    final original = Flashcard(
      id: 'card-001',
      front: 'O que é TCP?',
      back: 'Resposta antiga.',
      createdAt: DateTime(2026, 9, 27),
    );

    final atualizado = original.copyWith(back: 'Resposta atualizada.');

    expect(atualizado.id, original.id);
    expect(atualizado.front, original.front);
    expect(atualizado.back, 'Resposta atualizada.');
    expect(atualizado.createdAt, original.createdAt);

    expect(original.back, 'Resposta antiga.');
    expect(identical(original, atualizado), isFalse);
  });
}
