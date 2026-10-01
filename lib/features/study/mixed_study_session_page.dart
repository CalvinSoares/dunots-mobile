import 'package:flutter/material.dart';

import '../../core/models/flashcard.dart';
import '../../core/models/flashcard_session_summary.dart';
import '../challenges/data/challenge_repository.dart';
import '../challenges/domain/challenge.dart';
import '../flashcards/data/flashcard_repository.dart';
import '../flashcards/data/flashcard_session_repository.dart';
import '../flashcards/flashcard_srs.dart';

enum MixedStudyItemType { flashcard, challenge }

class MixedStudyItem {
  final MixedStudyItemType type;
  final Flashcard? flashcard;
  final Challenge? challenge;

  const MixedStudyItem._({required this.type, this.flashcard, this.challenge});

  factory MixedStudyItem.flashcard(Flashcard card) =>
      MixedStudyItem._(type: MixedStudyItemType.flashcard, flashcard: card);

  factory MixedStudyItem.challenge(Challenge challenge) => MixedStudyItem._(
    type: MixedStudyItemType.challenge,
    challenge: challenge,
  );
}

class MixedStudySessionPage extends StatefulWidget {
  final String? title;
  final List<Flashcard> cards;
  final List<Challenge> challenges;
  final FlashcardRepository flashcardRepository;
  final ChallengeRepository challengeRepository;
  final FlashcardSessionRepository? sessionRepository;

  const MixedStudySessionPage({
    super.key,
    this.title,
    required this.cards,
    required this.challenges,
    required this.flashcardRepository,
    required this.challengeRepository,
    this.sessionRepository,
  });

  @override
  State<MixedStudySessionPage> createState() => _MixedStudySessionPageState();
}

class _MixedStudySessionPageState extends State<MixedStudySessionPage> {
  late final List<MixedStudyItem> _items;
  late final TextEditingController _answerController;
  late final DateTime _startedAt;
  int _index = 0;
  bool _answered = false;
  bool _solutionVisible = false;
  bool _saving = false;
  bool _finished = false;
  String? _feedback;
  final Map<String, int> _flashcardRatings = {};
  final Map<String, int> _challengeRatings = {};

  MixedStudyItem get _current => _items[_index];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _answerController = TextEditingController();
    _items = _interleave(widget.cards, widget.challenges);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estudo misto')),
        body: const Center(child: Text('Nenhum item disponível para estudar.')),
      );
    }
    if (_finished) return _buildFinished(context);

    final progress = (_index + (_readyToRate ? 1 : 0)) / _items.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.title ?? 'Estudo misto'} · ${_index + 1}/${_items.length}',
        ),
        actions: [
          IconButton(
            tooltip: 'Sair da sessão',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                _current.type == MixedStudyItemType.flashcard
                    ? Icons.style_outlined
                    : Icons.code_outlined,
              ),
              label: Text(
                _current.type == MixedStudyItemType.flashcard
                    ? 'Flashcard'
                    : 'Desafio',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_current.type == MixedStudyItemType.flashcard)
            _buildFlashcard(context, _current.flashcard!)
          else
            _buildChallenge(context, _current.challenge!),
        ],
      ),
    );
  }

  bool get _readyToRate => _current.type == MixedStudyItemType.flashcard
      ? _answered
      : _solutionVisible;

  Widget _buildFlashcard(BuildContext context, Flashcard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pergunta', style: Theme.of(context).textTheme.labelLarge),
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
        const SizedBox(height: 18),
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
          _buildRatingArea(
            context,
            title: 'Resposta correta · como foi?',
            onRate: _rateFlashcard,
            labels: const {
              'difícil': 'Difícil',
              'bom': 'Bom',
              'fácil': 'Fácil',
            },
          ),
      ],
    );
  }

  Widget _buildChallenge(BuildContext context, Challenge challenge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(challenge.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            Chip(label: Text(challenge.difficulty.name)),
            ...challenge.tags.map((tag) => Chip(label: Text(tag))),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              challenge.notes.isEmpty
                  ? 'Resolva o desafio antes de revelar a solução.'
                  : challenge.notes,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (!_solutionVisible)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _solutionVisible = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Mostrar solução'),
            ),
          )
        else ...[
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                challenge.solution.isEmpty
                    ? 'Nenhuma solução cadastrada.'
                    : challenge.solution,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildRatingArea(
            context,
            title: 'Como foi?',
            onRate: _rateChallenge,
            labels: const {
              'again': 'Novamente',
              'hard': 'Difícil',
              'medium': 'Bom',
              'easy': 'Fácil',
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRatingArea(
    BuildContext context, {
    required String title,
    required Future<void> Function(String rating) onRate,
    required Map<String, String> labels,
  }) {
    if (_saving) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.entries
              .map(
                (entry) => OutlinedButton(
                  onPressed: () => onRate(entry.key),
                  child: Text(entry.value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _checkAnswer(Flashcard card) {
    if (_answered) return;
    if (_normalize(_answerController.text) != _normalize(card.back)) {
      setState(
        () => _feedback = 'A resposta precisa estar correta para continuar.',
      );
      return;
    }
    setState(() {
      _feedback = null;
      _answered = true;
    });
  }

  Future<void> _rateFlashcard(String rating) async {
    final reviewedAt = DateTime.now();
    final card = _current.flashcard!;
    setState(() => _saving = true);
    try {
      await widget.flashcardRepository.recordReview(
        cardId: card.id,
        rating: rating,
        reviewedAt: reviewedAt,
        dueAt: FlashcardScheduler.nextReviewAt(
          rating: rating,
          reviewedAt: reviewedAt,
        ),
      );
      _flashcardRatings.update(rating, (count) => count + 1, ifAbsent: () => 1);
      await _advance();
    } catch (_) {
      _showSaveError();
    }
  }

  Future<void> _rateChallenge(String rating) async {
    final challenge = _current.challenge!;
    setState(() => _saving = true);
    try {
      await widget.challengeRepository.recordReview(
        challengeId: challenge.id,
        rating: rating,
        reviewedAt: DateTime.now(),
      );
      _challengeRatings.update(rating, (count) => count + 1, ifAbsent: () => 1);
      await _advance();
    } catch (_) {
      _showSaveError();
    }
  }

  Future<void> _advance() async {
    if (_index == _items.length - 1) {
      await _persistFlashcardSummary();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _finished = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _index++;
      _answered = false;
      _solutionVisible = false;
      _feedback = null;
      _saving = false;
      _answerController.clear();
    });
  }

  Future<void> _persistFlashcardSummary() async {
    final repository = widget.sessionRepository;
    if (repository == null) return;
    final finishedAt = DateTime.now();
    final flashcardCount = _items
        .where((item) => item.type == MixedStudyItemType.flashcard)
        .length;
    if (flashcardCount == 0) return;
    await repository.create(
      FlashcardSessionSummary(
        id: 'mixed-session-${finishedAt.microsecondsSinceEpoch}',
        startedAt: _startedAt,
        finishedAt: finishedAt,
        cardCount: flashcardCount,
        difficultCount: _flashcardRatings['difícil'] ?? 0,
        goodCount: _flashcardRatings['bom'] ?? 0,
        easyCount: _flashcardRatings['fácil'] ?? 0,
      ),
    );
  }

  void _showSaveError() {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível salvar a revisão.')),
    );
  }

  Widget _buildFinished(BuildContext context) {
    final flashcardTotal = _flashcardRatings.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final challengeTotal = _challengeRatings.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title ?? 'Estudo misto'} concluído'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Sessão concluída',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${flashcardTotal + challengeTotal} itens revisados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Text(
              'Resumo por tipo',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _summaryCard(
              context,
              title: 'Flashcards · $flashcardTotal',
              icon: Icons.style_outlined,
              values: {
                'Difíceis': _flashcardRatings['difícil'] ?? 0,
                'Bons': _flashcardRatings['bom'] ?? 0,
                'Fáceis': _flashcardRatings['fácil'] ?? 0,
              },
            ),
            const SizedBox(height: 10),
            _summaryCard(
              context,
              title: 'Desafios · $challengeTotal',
              icon: Icons.code_outlined,
              values: {
                'Novamente': _challengeRatings['again'] ?? 0,
                'Difíceis': _challengeRatings['hard'] ?? 0,
                'Bons': _challengeRatings['medium'] ?? 0,
                'Fáceis': _challengeRatings['easy'] ?? 0,
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Voltar ao Hoje'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Map<String, int> values,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.entries
                  .map(
                    (entry) =>
                        Chip(label: Text('${entry.key}: ${entry.value}')),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  List<MixedStudyItem> _interleave(
    List<Flashcard> cards,
    List<Challenge> challenges,
  ) {
    final items = <MixedStudyItem>[];
    final length = cards.length > challenges.length
        ? cards.length
        : challenges.length;
    for (var index = 0; index < length; index++) {
      if (index < cards.length) {
        items.add(MixedStudyItem.flashcard(cards[index]));
      }
      if (index < challenges.length) {
        items.add(MixedStudyItem.challenge(challenges[index]));
      }
    }
    return items;
  }
}
