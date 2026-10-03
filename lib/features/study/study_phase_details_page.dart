import 'package:flutter/material.dart';

import '../../shared/widgets/dunots_modal.dart';

import '../../core/models/flashcard.dart';
import '../flashcards/data/flashcard_repository.dart';
import '../flashcards/flashcard_study_page.dart';
import 'data/study_phase_repository.dart';
import 'domain/study_phase.dart';
import 'study_phase_form_dialog.dart';

class StudyPhaseDetailsPage extends StatefulWidget {
  final StudyPhase phase;
  final StudyPhaseRepository phaseRepository;
  final FlashcardRepository flashcardRepository;

  const StudyPhaseDetailsPage({
    super.key,
    required this.phase,
    required this.phaseRepository,
    required this.flashcardRepository,
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
      body: SafeArea(
        child: FutureBuilder<_PhaseData>(
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
            final completed = _phase.completedItems(flashcards: data.cards);
            final progress = _phase.progress(flashcards: data.cards);
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
                  onPressed: data.cards.isEmpty ? null : () => _start(data),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar fase'),
                ),
                const SizedBox(height: 22),
                Text(
                  'Flashcards da fase',
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
                if (data.cards.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Esta fase ainda não possui flashcards.'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _reload() {
    _dataFuture = widget.flashcardRepository.getAll().then(
      (cards) => _PhaseData(cards: _selectCards(cards), allCards: cards),
    );
  }

  List<Flashcard> _selectCards(List<Flashcard> cards) => cards
      .where((card) => _phase.flashcardIds.contains(card.id))
      .toList(growable: false);

  Future<void> _edit() async {
    final data = await _dataFuture;
    if (!mounted) return;
    final updated = await showDunotsDrawer<StudyPhase>(
      context: context,
      builder: (_) =>
          StudyPhaseFormDialog(initialPhase: _phase, flashcards: data.allCards),
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
        builder: (_) => FlashcardStudyPage(
          cards: data.cards,
          repository: widget.flashcardRepository,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }
}

class _PhaseData {
  final List<Flashcard> cards;
  final List<Flashcard> allCards;

  const _PhaseData({required this.cards, required this.allCards});
}
