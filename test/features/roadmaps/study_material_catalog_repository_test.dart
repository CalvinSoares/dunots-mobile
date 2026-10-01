import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/diagrams/data/diagram_repository.dart';
import 'package:dunots_mobile/features/diagrams/domain/study_diagram.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_material_catalog_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';

void main() {
  test('o catálogo expõe questões reais como materiais vinculáveis', () async {
    final repository = StudyMaterialCatalogRepository(
      flashcardRepository: InMemoryFlashcardRepository(
        cards: [
          Flashcard(
            id: 'card-1',
            front: 'Frente',
            back: 'Verso',
            createdAt: DateTime(2026, 9, 30),
          ),
        ],
      ),
      questionRepository: InMemoryQuestionRepository(
        questions: [
          Question(
            id: 'question-42',
            number: 42,
            statement: 'Qual é a função do switch?',
            alternatives: const ['Comutar quadros', 'Resolver nomes'],
            correctAlternativeIndex: 0,
            explanation: '',
            contest: 'Teste',
            role: 'Redes',
            createdAt: DateTime(2026, 9, 30),
          ),
        ],
      ),
      diagramRepository: InMemoryDiagramRepository(
        items: [
          StudyDiagram(
            id: 'diagram-1',
            title: 'Topologia em estrela',
            description: 'Concentrador central',
            createdAt: DateTime(2026, 9, 30),
          ),
        ],
      ),
    );

    final materials = await repository.getAll();
    final question = materials.singleWhere(
      (material) => material.id == 'question-42',
    );

    expect(question.type, StudyMaterialType.question);
    expect(question.title, 'Qual é a função do switch?');
    expect(question.subtitle, '#42 · Questão · Redes · Teste');

    final diagram = materials.singleWhere(
      (material) => material.id == 'diagram-1',
    );
    expect(diagram.type, StudyMaterialType.diagram);
    expect(diagram.title, 'Topologia em estrela');
    expect(diagram.subtitle, 'Fluxograma · Concentrador central');
  });
}
