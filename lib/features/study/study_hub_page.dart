import 'package:flutter/material.dart';

import '../flashcards/data/flashcard_repository.dart';
import '../flashcards/data/flashcard_review_preferences_repository.dart';
import '../flashcards/data/flashcard_session_repository.dart';
import '../flashcards/flashcards_preview_page.dart';
import '../questions/data/question_repository.dart';

/// Área principal de estudo do aplicativo.
class StudyHubPage extends StatefulWidget {
  final bool showHeader;
  final FlashcardRepository? flashcardRepository;
  final FlashcardSessionRepository? flashcardSessionRepository;
  final FlashcardReviewPreferencesRepository?
  flashcardReviewPreferencesRepository;
  final QuestionRepository? questionRepository;

  const StudyHubPage({
    super.key,
    this.showHeader = true,
    this.flashcardRepository,
    this.flashcardSessionRepository,
    this.flashcardReviewPreferencesRepository,
    this.questionRepository,
  });

  @override
  State<StudyHubPage> createState() => _StudyHubPageState();
}

class _StudyHubPageState extends State<StudyHubPage> {
  @override
  Widget build(BuildContext context) {
    return FlashcardsPreviewPage(
      repository: widget.flashcardRepository,
      questionRepository: widget.questionRepository,
      sessionRepository: widget.flashcardSessionRepository,
      preferencesRepository: widget.flashcardReviewPreferencesRepository,
      showHeader: widget.showHeader,
    );
  }
}
