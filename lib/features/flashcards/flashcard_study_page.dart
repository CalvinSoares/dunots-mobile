import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';

import '../../shared/widgets/study_widgets.dart';
import '../questions/data/question_repository.dart';
import '../questions/question_details_page.dart';
import '../roadmaps/data/study_material_repository.dart';
import '../roadmaps/domain/study_material.dart';
import 'data/flashcard_repository.dart';
import 'data/flashcard_session_repository.dart';
import 'flashcard_details_page.dart';
import 'flashcard_srs.dart';

class FlashcardStudyPage extends StatefulWidget {
  final List<Flashcard> cards;
  final FlashcardRepository? repository;
  final QuestionRepository? questionRepository;
  final StudyMaterialRepository? materialRepository;
  final FlashcardSessionRepository? sessionRepository;

  const FlashcardStudyPage({
    super.key,
    required this.cards,
    this.repository,
    this.questionRepository,
    this.materialRepository,
    this.sessionRepository,
  });

  @override
  State<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends State<FlashcardStudyPage> {
  late final TextEditingController _answerController;
  late final DateTime _startedAt;
  int _currentIndex = 0;
  bool _answered = false;
  bool _finished = false;
  String? _feedback;
  final Map<String, int> _ratingCounts = {};

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revisão de flashcards')),
        body: const StudyEmptyState(
          title: 'Nenhum flashcard para revisar.',
          detail: 'Cadastre um cartão antes de iniciar uma sessão.',
          icon: Icons.style_outlined,
        ),
      );
    }

    if (_finished) {
      return _buildFinished(context);
    }

    final card = widget.cards[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisão · ${_currentIndex + 1}/${widget.cards.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value:
                  (_currentIndex + (_answered ? 1 : 0)) / widget.cards.length,
            ),
            const SizedBox(height: 24),
            Text(
              'Pergunta',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  card.front,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _answerController,
              enabled: !_answered,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _checkAnswer(card),
              decoration: InputDecoration(
                labelText: 'Sua resposta',
                hintText: 'Digite a resposta antes de conferir',
                errorText: _feedback,
                suffixIcon: _answered ? const Icon(Icons.check_circle) : null,
              ),
            ),
            const SizedBox(height: 12),
            if (!_answered)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _checkAnswer(card),
                  icon: const Icon(Icons.check),
                  label: const Text('Conferir resposta'),
                ),
              )
            else
              _buildAnswerResult(context, card),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerResult(BuildContext context, Flashcard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resposta correta',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(card.back),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Como foi?', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (card.linkedMaterialIds.isNotEmpty &&
            widget.materialRepository != null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showRelatedMaterials(card),
              icon: const Icon(Icons.link),
              label: Text(
                'Ver materiais relacionados (${card.linkedMaterialIds.length})',
              ),
            ),
          ),
        if (card.linkedMaterialIds.isNotEmpty &&
            widget.materialRepository != null)
          const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _classify('difícil'),
              child: const Text('Difícil'),
            ),
            OutlinedButton(
              onPressed: () => _classify('bom'),
              child: const Text('Bom'),
            ),
            FilledButton(
              onPressed: () => _classify('fácil'),
              child: const Text('Fácil'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinished(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisão concluída')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Sessão concluída',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text('${widget.cards.length} flashcards respondidos.'),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryChip('Difíceis', _ratingCounts['difícil'] ?? 0),
                  _summaryChip('Bons', _ratingCounts['bom'] ?? 0),
                  _summaryChip('Fáceis', _ratingCounts['fácil'] ?? 0),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar aos flashcards'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkAnswer(Flashcard card) {
    if (_answered) return;
    if (_normalize(_answerController.text) != _normalize(card.back)) {
      setState(() {
        _feedback = 'A resposta precisa estar correta para continuar.';
      });
      return;
    }

    setState(() {
      _feedback = null;
      _answered = true;
    });
  }

  Future<void> _classify(String classification) async {
    if (!_answered) return;
    final reviewedAt = DateTime.now();
    final repository = widget.repository;
    if (repository != null) {
      await repository.recordReview(
        cardId: widget.cards[_currentIndex].id,
        rating: classification,
        reviewedAt: reviewedAt,
        dueAt: FlashcardScheduler.nextReviewAt(
          rating: classification,
          reviewedAt: reviewedAt,
        ),
      );
    }
    _ratingCounts.update(
      classification,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (_currentIndex == widget.cards.length - 1) {
      await _persistSummary();
      if (!mounted) return;
      setState(() => _finished = true);
      return;
    }

    setState(() {
      _currentIndex++;
      _answered = false;
      _feedback = null;
      _answerController.clear();
    });
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _summaryChip(String label, int count) {
    return Chip(label: Text('$label: $count'));
  }

  Future<void> _persistSummary() async {
    final repository = widget.sessionRepository;
    if (repository == null) return;
    final finishedAt = DateTime.now();
    await repository.create(
      FlashcardSessionSummary(
        id: 'flashcard-session-${finishedAt.microsecondsSinceEpoch}',
        startedAt: _startedAt,
        finishedAt: finishedAt,
        cardCount: widget.cards.length,
        difficultCount: _ratingCounts['difícil'] ?? 0,
        goodCount: _ratingCounts['bom'] ?? 0,
        easyCount: _ratingCounts['fácil'] ?? 0,
      ),
    );
  }

  Future<void> _showRelatedMaterials(Flashcard card) async {
    final repository = widget.materialRepository;
    if (repository == null) return;
    final materials = (await repository.getAll())
        .where((material) => card.linkedMaterialIds.contains(material.id))
        .toList(growable: false);
    if (!mounted) return;
    final selected = await showDialog<StudyMaterial>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Materiais relacionados'),
        content: SizedBox(
          width: 520,
          height: 360,
          child: materials.isEmpty
              ? const Center(child: Text('Nenhum material disponível.'))
              : ListView.separated(
                  itemCount: materials.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final material = materials[index];
                    return ListTile(
                      leading: Icon(_materialIcon(material.type)),
                      title: Text(material.title),
                      subtitle: Text(material.subtitle),
                      onTap: () => Navigator.of(context).pop(material),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (selected != null && mounted) {
      await _openMaterial(selected);
    }
  }

  Future<void> _openMaterial(StudyMaterial material) async {
    switch (material.type) {
      case StudyMaterialType.question:
        final repository = widget.questionRepository;
        if (repository == null) return;
        final question = (await repository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (question != null && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionDetailsPage(question: question),
            ),
          );
        }
      case StudyMaterialType.flashcard:
        final repository = widget.repository;
        if (repository == null) return;
        final linkedCard = (await repository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (linkedCard != null &&
            linkedCard.id != widget.cards[_currentIndex].id &&
            mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlashcardDetailsPage(
                card: linkedCard,
                flashcardRepository: widget.repository,
                questionRepository: widget.questionRepository,
                materialRepository: widget.materialRepository,
              ),
            ),
          );
        }
      case StudyMaterialType.document:
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(material.title),
            content: Text(material.subtitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
    }
  }

  IconData _materialIcon(StudyMaterialType type) {
    return switch (type) {
      StudyMaterialType.flashcard => Icons.style_outlined,
      StudyMaterialType.question => Icons.quiz_outlined,
      StudyMaterialType.document => Icons.description_outlined,
    };
  }
}
