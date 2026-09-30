import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/flashcard_study_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';

void main() {
  test('o catálogo transforma flashcards em materiais vinculáveis', () async {
    final flashcardRepository = InMemoryFlashcardRepository(
      cards: [
        Flashcard(
          id: 'card-custom',
          front: 'O que é uma VLAN?',
          back: 'Uma rede lógica segmentada.',
          createdAt: DateTime(2026, 9, 30),
        ),
      ],
    );
    final materialRepository = FlashcardStudyMaterialRepository(
      flashcardRepository: flashcardRepository,
    );

    final materials = await materialRepository.getAll();

    expect(materials.first.id, 'card-custom');
    expect(materials.first.type, StudyMaterialType.flashcard);
    expect(materials.first.title, 'O que é uma VLAN?');
  });
}
