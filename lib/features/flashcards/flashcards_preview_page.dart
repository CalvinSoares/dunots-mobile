import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';

import '../../shared/widgets/study_widgets.dart';
import 'data/flashcard_repository.dart';
import 'data/flashcard_session_repository.dart';
import '../roadmaps/data/study_material_catalog_repository.dart';
import '../roadmaps/domain/study_material.dart';
import 'flashcard_form_dialog.dart';
import 'flashcard_list_item.dart';
import 'flashcard_session_history_page.dart';
import 'flashcard_study_page.dart';

class FlashcardsPreviewPage extends StatefulWidget {
  final FlashcardRepository? repository;
  final QuestionRepository? questionRepository;
  final FlashcardSessionRepository? sessionRepository;

  const FlashcardsPreviewPage({
    super.key,
    this.repository,
    this.questionRepository,
    this.sessionRepository,
  });

  @override
  State<FlashcardsPreviewPage> createState() => _FlashcardsPreviewPageState();
}

class _FlashcardsPreviewPageState extends State<FlashcardsPreviewPage> {
  late final FlashcardRepository _repository;
  late final StudyMaterialCatalogRepository _materialRepository;
  late final Future<List<Flashcard>> _cardsFuture;
  late final FlashcardSessionRepository _sessionRepository;
  late Future<List<FlashcardSessionSummary>> _todaySessionsFuture;
  String _filter = 'all';
  String _search = '';
  String _selectedTag = '';
  String _sort = 'due';
  int _dailyLimit = 20;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryFlashcardRepository();
    _sessionRepository =
        widget.sessionRepository ?? InMemoryFlashcardSessionRepository();
    _materialRepository = StudyMaterialCatalogRepository(
      flashcardRepository: _repository,
      questionRepository:
          widget.questionRepository ?? InMemoryQuestionRepository(),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.style_outlined,
      title: 'Flashcards',
      subtitle: 'A revisão espaçada vai morar aqui.',
      child: FutureBuilder<List<Flashcard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudyLoadingState(message: 'Carregando flashcards...');
          }

          if (snapshot.hasError) {
            return StudyErrorState(
              message: 'Não foi possível carregar os flashcards.',
              onRetry: () => setState(_reload),
            );
          }

          final cards = snapshot.data ?? const [];
          if (cards.isEmpty) {
            return const StudyEmptyState(
              title: 'Nenhum flashcard cadastrado ainda.',
              detail: 'Cadastre um cartão para começar a revisar.',
              icon: Icons.style_outlined,
            );
          }

          final now = DateTime.now();
          final dueCards = cards
              .where((card) => card.isDueAt(now))
              .toList(growable: false);
          final newCards = cards
              .where((card) => card.reviewCount == 0)
              .toList(growable: false);
          final reviewedCards = cards
              .where((card) => card.reviewCount > 0)
              .toList(growable: false);
          final difficultCards = cards
              .where((card) => card.lastRating == 'difícil')
              .toList(growable: false);
          final situationCards = switch (_filter) {
            'due' => dueCards,
            'new' => newCards,
            'reviewed' => reviewedCards,
            'difficult' => difficultCards,
            _ => cards,
          };
          final visibleCards = situationCards
              .where(_matchesSearch)
              .where(
                (card) =>
                    _selectedTag.isEmpty || card.tags.contains(_selectedTag),
              )
              .toList();
          visibleCards.sort(_compareCards);
          final studyCards = visibleCards
              .where((card) => card.isDueAt(now))
              .take(_dailyLimit == 0 ? visibleCards.length : _dailyLimit)
              .toList(growable: false);
          final tags = cards.expand((card) => card.tags).toSet().toList()
            ..sort();
          return Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openHistory,
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('Histórico'),
                    ),
                    FilledButton.icon(
                      onPressed: _createFlashcard,
                      icon: const Icon(Icons.add),
                      label: const Text('Novo flashcard'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<FlashcardSessionSummary>>(
                future: _todaySessionsFuture,
                builder: (context, summarySnapshot) {
                  if (summarySnapshot.connectionState != ConnectionState.done) {
                    return const SizedBox.shrink();
                  }
                  return _buildTodaySummary(summarySnapshot.data ?? const []);
                },
              ),
              const SizedBox(height: 12),
              _buildRecommendation(difficultCards),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar flashcards',
                  hintText: 'Pergunta, resposta, código ou tag',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _sort,
                decoration: const InputDecoration(labelText: 'Ordenar por'),
                items: const [
                  DropdownMenuItem(
                    value: 'due',
                    child: Text('Próxima revisão'),
                  ),
                  DropdownMenuItem(
                    value: 'alphabetical',
                    child: Text('Alfabética'),
                  ),
                  DropdownMenuItem(
                    value: 'reviews',
                    child: Text('Mais revisados'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dailyLimit,
                decoration: const InputDecoration(labelText: 'Limite diário'),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('Até 10 cards')),
                  DropdownMenuItem(value: 20, child: Text('Até 20 cards')),
                  DropdownMenuItem(value: 50, child: Text('Até 50 cards')),
                  DropdownMenuItem(value: 0, child: Text('Todos os cards')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _dailyLimit = value);
                },
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTagChip('', 'Todas'),
                      ...tags.map((tag) => _buildTagChip(tag, tag)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${dueCards.length} pendentes hoje · '
                  '${reviewedCards.length} já revisados',
                  style: const TextStyle(color: Color(0xFFB6B7AD)),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('all', 'Todos', cards.length),
                    _buildFilterChip('due', 'Vencidos', dueCards.length),
                    _buildFilterChip('new', 'Novos', newCards.length),
                    _buildFilterChip(
                      'difficult',
                      'Difíceis',
                      difficultCards.length,
                    ),
                    _buildFilterChip(
                      'reviewed',
                      'Revisados',
                      reviewedCards.length,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: studyCards.isEmpty
                      ? null
                      : () => _startStudy(studyCards),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    studyCards.isEmpty
                        ? 'Nenhuma revisão pendente'
                        : 'Iniciar revisão · ${studyCards.length} pendentes',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (visibleCards.isEmpty)
                const StudyEmptyState(
                  title: 'Nenhum flashcard neste filtro.',
                  detail: 'Escolha outro filtro para ver seus cartões.',
                  icon: Icons.filter_alt_off_outlined,
                )
              else
                ...visibleCards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FlashcardListItem(
                      card: card,
                      onEdit: () => _editFlashcard(card),
                      onDelete: () => _confirmDelete(card),
                      flashcardRepository: _repository,
                      questionRepository: widget.questionRepository,
                      materialRepository: _materialRepository,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    _cardsFuture = _repository.getAll();
    _todaySessionsFuture = _sessionRepository.getForDay(DateTime.now());
  }

  Future<void> _startStudy(List<Flashcard> cards) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardStudyPage(
          cards: cards,
          repository: _repository,
          questionRepository: widget.questionRepository,
          materialRepository: _materialRepository,
          sessionRepository: _sessionRepository,
        ),
      ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FlashcardSessionHistoryPage(repository: _sessionRepository),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    return FilterChip(
      selected: _filter == value,
      label: Text('$label ($count)'),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildTagChip(String value, String label) {
    return FilterChip(
      selected: _selectedTag == value,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedTag = value),
    );
  }

  Widget _buildTodaySummary(List<FlashcardSessionSummary> sessions) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final answered = sessions.fold<int>(
      0,
      (total, session) => total + session.answeredCount,
    );
    final difficult = sessions.fold<int>(
      0,
      (total, session) => total + session.difficultCount,
    );
    final good = sessions.fold<int>(
      0,
      (total, session) => total + session.goodCount,
    );
    final easy = sessions.fold<int>(
      0,
      (total, session) => total + session.easyCount,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo de hoje',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$answered cards respondidos em ${sessions.length} sessão(ões).',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Difíceis: $difficult')),
                Chip(label: Text('Bons: $good')),
                Chip(label: Text('Fáceis: $easy')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(List<Flashcard> difficultCards) {
    if (difficultCards.isEmpty) return const SizedBox.shrink();
    final tagCounts = <String, int>{};
    for (final card in difficultCards) {
      for (final tag in card.tags) {
        tagCounts.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final orderedTags = tagCounts.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final leadingTag = orderedTags.isEmpty ? null : orderedTags.first.key;
    return Card(
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recomendação de revisão',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${difficultCards.length} card(s) foram classificados como difíceis.',
            ),
            if (leadingTag != null) ...[
              const SizedBox(height: 4),
              Text('Tema para priorizar: $leadingTag.'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: orderedTags
                    .map(
                      (entry) =>
                          Chip(label: Text('${entry.key}: ${entry.value}')),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _filter = 'difficult';
                _search = '';
                _selectedTag = '';
              }),
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Ver cards difíceis'),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSearch(Flashcard card) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return card.front.toLowerCase().contains(query) ||
        card.back.toLowerCase().contains(query) ||
        card.code.toLowerCase().contains(query) ||
        card.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  int _compareCards(Flashcard first, Flashcard second) {
    switch (_sort) {
      case 'alphabetical':
        return first.front.toLowerCase().compareTo(second.front.toLowerCase());
      case 'reviews':
        return second.reviewCount.compareTo(first.reviewCount);
      case 'due':
      default:
        final firstDue = first.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final secondDue =
            second.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return firstDue.compareTo(secondDue);
    }
  }

  Future<void> _createFlashcard() async {
    final materials = await _loadAvailableMaterials();
    if (!mounted) return;
    final card = await showDialog<Flashcard>(
      context: context,
      builder: (_) => FlashcardFormDialog(availableMaterials: materials),
    );
    if (card == null || !mounted) return;
    await _save(() => _repository.create(card));
  }

  Future<void> _editFlashcard(Flashcard card) async {
    final materials = await _loadAvailableMaterials(
      excludedMaterialId: card.id,
    );
    if (!mounted) return;
    final updated = await showDialog<Flashcard>(
      context: context,
      builder: (_) =>
          FlashcardFormDialog(initialCard: card, availableMaterials: materials),
    );
    if (updated == null || !mounted) return;
    await _save(() => _repository.update(updated));
  }

  Future<void> _confirmDelete(Flashcard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir flashcard?'),
        content: Text('O flashcard "${card.front}" será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _save(() => _repository.delete(card.id));
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
      _materialRepository.invalidate();
      if (mounted) setState(_reload);
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<List<StudyMaterial>> _loadAvailableMaterials({
    String? excludedMaterialId,
  }) async {
    final materials = await _materialRepository.getAll();
    return materials
        .where((material) => material.id != excludedMaterialId)
        .toList(growable: false);
  }
}
