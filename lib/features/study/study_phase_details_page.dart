import 'package:flutter/material.dart';

import '../../core/models/flashcard.dart';
import '../challenges/data/challenge_repository.dart';
import '../challenges/domain/challenge.dart';
import '../flashcards/data/flashcard_repository.dart';
import '../study/mixed_study_session_page.dart';
import 'data/study_phase_repository.dart';
import 'domain/study_phase.dart';
import 'study_phase_form_dialog.dart';

class StudyPhaseDetailsPage extends StatefulWidget {
  final StudyPhase phase;
  final StudyPhaseRepository phaseRepository;
  final FlashcardRepository flashcardRepository;
  final ChallengeRepository challengeRepository;

  const StudyPhaseDetailsPage({
    super.key,
    required this.phase,
    required this.phaseRepository,
    required this.flashcardRepository,
    required this.challengeRepository,
  });

  @override
  State<StudyPhaseDetailsPage> createState() => _StudyPhaseDetailsPageState();
}

class _StudyPhaseDetailsPageState extends State<StudyPhaseDetailsPage> {
  late StudyPhase _phase;
  late Future<_PhaseData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _phase = widget.phase;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_phase.title),
        actions: [
          IconButton(
            tooltip: 'Editar fase',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: FutureBuilder<_PhaseData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Não foi possível carregar a fase.'),
            );
          }
          final data = snapshot.data!;
          final completed = _phase.completedItems(
            flashcards: data.cards,
            challenges: data.challenges,
          );
          final progress = _phase.progress(
            flashcards: data.cards,
            challenges: data.challenges,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              if (_phase.description.isNotEmpty) ...[
                Text(_phase.description),
                const SizedBox(height: 16),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text('$completed/${_phase.totalItems} concluídos'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).round()}% da fase concluída'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: data.cards.isEmpty && data.challenges.isEmpty
                    ? null
                    : () => _start(data),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar fase'),
              ),
              const SizedBox(height: 22),
              Text(
                'Conteúdo da fase',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...data.cards.map(
                (card) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.style_outlined),
                  title: Text(
                    card.front,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    card.lastReviewedAt == null ? 'Pendente' : 'Revisado',
                  ),
                ),
              ),
              ...data.challenges.map(
                (challenge) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.code_outlined),
                  title: Text(challenge.title),
                  subtitle: Text(
                    challenge.solvedAt == null ? 'Pendente' : 'Revisado',
                  ),
                ),
              ),
              if (data.cards.isEmpty && data.challenges.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Esta fase ainda não possui itens associados.'),
                ),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    _dataFuture =
        Future.wait([
          widget.flashcardRepository.getAll(),
          widget.challengeRepository.getAll(),
        ]).then((values) {
          final allCards = values[0] as List<Flashcard>;
          final allChallenges = values[1] as List<Challenge>;
          return _PhaseData(
            cards: _selectCards(allCards),
            challenges: _selectChallenges(allChallenges),
            allCards: allCards,
            allChallenges: allChallenges,
          );
        });
  }

  List<Flashcard> _selectCards(List<Flashcard> cards) => cards
      .where((card) => _phase.flashcardIds.contains(card.id))
      .toList(growable: false);

  List<Challenge> _selectChallenges(List<Challenge> challenges) => challenges
      .where((challenge) => _phase.challengeIds.contains(challenge.id))
      .toList(growable: false);

  Future<void> _edit() async {
    final data = await _dataFuture;
    if (!mounted) return;
    final updated = await showDialog<StudyPhase>(
      context: context,
      builder: (_) => StudyPhaseFormDialog(
        initialPhase: _phase,
        flashcards: data.allCards,
        challenges: data.allChallenges,
      ),
    );
    if (updated == null) return;
    await widget.phaseRepository.update(updated);
    if (!mounted) return;
    setState(() {
      _phase = updated;
      _reload();
    });
  }

  Future<void> _start(_PhaseData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MixedStudySessionPage(
          title: _phase.title,
          cards: data.cards,
          challenges: data.challenges,
          flashcardRepository: widget.flashcardRepository,
          challengeRepository: widget.challengeRepository,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }
}

class _PhaseData {
  final List<Flashcard> cards;
  final List<Challenge> challenges;
  final List<Flashcard> allCards;
  final List<Challenge> allChallenges;

  const _PhaseData({
    required this.cards,
    required this.challenges,
    required this.allCards,
    required this.allChallenges,
  });
}
