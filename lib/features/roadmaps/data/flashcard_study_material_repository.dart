import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';

import '../domain/study_material.dart';
import 'study_material_repository.dart';

class FlashcardStudyMaterialRepository implements StudyMaterialRepository {
  final FlashcardRepository flashcardRepository;

  const FlashcardStudyMaterialRepository({required this.flashcardRepository});

  @override
  Future<List<StudyMaterial>> getAll() async {
    final cards = await flashcardRepository.getAll();
    return [
      ...cards.map(_fromFlashcard),
      const StudyMaterial(
        id: 'question-001',
        type: StudyMaterialType.question,
        title: 'Qual é a função da camada de transporte?',
        subtitle: 'Questão · Redes',
      ),
      const StudyMaterial(
        id: 'question-002',
        type: StudyMaterialType.question,
        title: 'Qual topologia usa um concentrador central?',
        subtitle: 'Questão · Infraestrutura',
      ),
      const StudyMaterial(
        id: 'document-001',
        type: StudyMaterialType.document,
        title: 'Resumo de arquiteturas de rede',
        subtitle: 'Material de estudo',
      ),
    ];
  }

  StudyMaterial _fromFlashcard(Flashcard card) {
    return StudyMaterial(
      id: card.id,
      type: StudyMaterialType.flashcard,
      title: card.front,
      subtitle: 'Flashcard',
    );
  }
}
