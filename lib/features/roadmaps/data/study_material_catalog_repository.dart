import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';

import '../domain/study_material.dart';
import 'study_document_repository.dart';
import 'study_material_repository.dart';

class StudyMaterialCatalogRepository implements StudyMaterialRepository {
  final FlashcardRepository flashcardRepository;
  final QuestionRepository questionRepository;
  final StudyDocumentRepository? documentRepository;

  StudyMaterialCatalogRepository({
    required this.flashcardRepository,
    required this.questionRepository,
    this.documentRepository,
  });

  List<StudyMaterial>? _cache;

  @override
  Future<List<StudyMaterial>> getAll() async {
    final cached = _cache;
    if (cached != null) return List.unmodifiable(cached);
    final cards = await flashcardRepository.getAll();
    final questions = await questionRepository.getAll();
    final documents = await documentRepository?.getAll() ?? const [];
    final materials = [
      ...cards.map(_fromFlashcard),
      ...questions.map(_fromQuestion),
      ...documents.map(
        (document) => StudyMaterial(
          id: document.id,
          type: StudyMaterialType.document,
          title: document.title,
          subtitle: document.subtitle,
        ),
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
