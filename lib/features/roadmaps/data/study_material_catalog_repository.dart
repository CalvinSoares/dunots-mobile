import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';

import '../domain/study_material.dart';
import 'study_material_repository.dart';

class StudyMaterialCatalogRepository implements StudyMaterialRepository {
  final FlashcardRepository flashcardRepository;
  final QuestionRepository questionRepository;

  StudyMaterialCatalogRepository({
    required this.flashcardRepository,
    required this.questionRepository,
  });

  List<StudyMaterial>? _cache;

  @override
  Future<List<StudyMaterial>> getAll() async {
    final cached = _cache;
    if (cached != null) return List.unmodifiable(cached);
    final cards = await flashcardRepository.getAll();
    final questions = await questionRepository.getAll();
    final materials = [
      ...cards.map(_fromFlashcard),
      ...questions.map(_fromQuestion),
      const StudyMaterial(
        id: 'document-001',
        type: StudyMaterialType.document,
        title: 'Resumo de arquiteturas de rede',
        subtitle: 'Material de estudo',
      ),
    ];
    _cache = materials;
    return List.unmodifiable(materials);
  }

  void invalidate() {
    _cache = null;
  }

  StudyMaterial _fromFlashcard(Flashcard card) {
    return StudyMaterial(
      id: card.id,
      type: StudyMaterialType.flashcard,
      title: card.front,
      subtitle: 'Flashcard',
    );
  }

  StudyMaterial _fromQuestion(Question question) {
    final number = question.number == null ? '' : '#${question.number} · ';
    final contest = question.contest.isEmpty ? '' : ' · ${question.contest}';
    final topic = question.topic.isEmpty ? '' : ' · ${question.topic}';
    final exam = question.exam.isEmpty ? '' : ' · ${question.exam}';
    return StudyMaterial(
      id: question.id,
      type: StudyMaterialType.question,
      title: question.statement,
      subtitle: '${number}Questão · ${question.role}$contest$topic$exam',
    );
  }
}
