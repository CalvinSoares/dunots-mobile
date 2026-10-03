import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/models/flashcard_review_preferences.dart';
import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';

import '../../shared/widgets/dunots_modal.dart';
import '../../shared/widgets/study_widgets.dart';
import '../../app/dunots_theme.dart';
import 'data/flashcard_repository.dart';
import 'data/flashcard_review_preferences_repository.dart';
import 'data/flashcard_session_repository.dart';
import '../roadmaps/data/study_material_catalog_repository.dart';
import '../roadmaps/domain/study_material.dart';
import 'flashcard_form_dialog.dart';
import 'flashcard_list_item.dart';
import 'flashcard_progress_page.dart';
import 'flashcard_session_history_page.dart';
import 'flashcard_study_page.dart';

class FlashcardsPreviewPage extends StatefulWidget {
  final bool showHeader;
  final FlashcardRepository? repository;
  final QuestionRepository? questionRepository;
  final FlashcardSessionRepository? sessionRepository;
  final FlashcardReviewPreferencesRepository? preferencesRepository;

  const FlashcardsPreviewPage({
    super.key,
    this.showHeader = true,
    this.repository,
    this.questionRepository,
    this.sessionRepository,
    this.preferencesRepository,
  });

  @override
  State<FlashcardsPreviewPage> createState() => _FlashcardsPreviewPageState();
}

class _FlashcardsPreviewPageState extends State<FlashcardsPreviewPage> {
  late final FlashcardRepository _repository;
  late final StudyMaterialCatalogRepository _materialRepository;
  late final Future<List<Flashcard>> _cardsFuture;
  List<Flashcard>? _cardsCache;
  late final FlashcardSessionRepository _sessionRepository;
  late final FlashcardReviewPreferencesRepository _preferencesRepository;
  late Future<List<FlashcardSessionSummary>> _todaySessionsFuture;
  String _filter = 'all';
  String _search = '';
  String _selectedTag = '';
  String _sort = 'due';
  int _dailyLimit = 20;
  int _dailyGoal = 20;
  int _weeklyGoal = 100;
  bool _preferRecommended = false;
  bool _reminderEnabled = true;
  int _reminderHour = 0;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryFlashcardRepository();
    _sessionRepository =
        widget.sessionRepository ?? InMemoryFlashcardSessionRepository();
    _preferencesRepository =
        widget.preferencesRepository ??
        InMemoryFlashcardReviewPreferencesRepository();
    _materialRepository = StudyMaterialCatalogRepository(
      flashcardRepository: _repository,
      questionRepository:
          widget.questionRepository ?? InMemoryQuestionRepository(),
    );
    _reload();
    unawaited(_loadPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: FutureBuilder<List<Flashcard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          final cards = _cardsCache ?? snapshot.data;
          if (snapshot.connectionState != ConnectionState.done &&
              cards == null) {
            return const StudyLoadingState(message: 'Carregando flashcards...');
          }

          if (snapshot.hasError && cards == null) {
            return StudyErrorState(
              message: 'Não foi possível carregar os flashcards.',
              onRetry: () => setState(_reload),
            );
          }

          if (cards == null) {
            return const StudyEmptyState(
              title: 'Nenhum flashcard cadastrado ainda.',
              detail: 'Cadastre um cartão para começar a revisar.',
              icon: Icons.style_outlined,
            );
          }

          if (cards.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopActions(),
                const SizedBox(height: 36),
                const StudyEmptyState(
                  title: 'Nenhum flashcard cadastrado ainda.',
                  detail: 'Crie um cartão para começar a revisar.',
                  icon: Icons.style_outlined,
                ),
              ],
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
          final recommendedCards =
              _buildRecommendedCards(
                    difficultCards: difficultCards,
                    dueCards: dueCards,
                  )
                  .take(_dailyLimit == 0 ? cards.length : _dailyLimit)
                  .toList(growable: false);
          final activeStudyCards = _preferRecommended
              ? recommendedCards
              : studyCards;
          final tags = cards.expand((card) => card.tags).toSet().toList()
            ..sort();
          final filtersActive = _filter != 'all' || _selectedTag.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopActions(),
              const SizedBox(height: 16),
              StudyFocusCard(
                eyebrow: activeStudyCards.isEmpty
                    ? 'Revisão concluída'
                    : 'Sessão recomendada',
                eyebrowIcon: activeStudyCards.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.play_circle_outline,
                title: activeStudyCards.isEmpty
                    ? 'Nenhum card pendente agora'
                    : '${activeStudyCards.length} cards para revisar',
                detail: activeStudyCards.isEmpty
                    ? '${newCards.length} novos disponíveis para quando quiser continuar.'
                    : '${dueCards.length} pendentes hoje · ${newCards.length} novos · limite de $_dailyLimit por sessão.',
                actionIcon: activeStudyCards.isEmpty
                    ? Icons.style_outlined
                    : Icons.play_arrow_rounded,
                actionLabel: activeStudyCards.isEmpty
                    ? 'Ver todos os cards'
                    : 'Iniciar sessão',
                onPressed: activeStudyCards.isEmpty
                    ? () => setState(() => _filter = 'all')
                    : () => _startStudy(activeStudyCards),
              ),
              const SizedBox(height: 14),
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
              _buildRecommendation(difficultCards, dueCards),
              if (difficultCards.isNotEmpty) const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: StudySearchField(
                      hintText: 'Buscar cards',
                      query: _search,
                      onChanged: (value) => setState(() => _search = value),
                      onClear: () => setState(() => _search = ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StudyFilterButton(
                    active: filtersActive,
                    tooltip: 'Filtrar flashcards',
                    onPressed: () => _showFlashcardFilters(
                      tags: tags,
                      allCards: cards,
                      dueCards: dueCards,
                      newCards: newCards,
                      difficultCards: difficultCards,
                      reviewedCards: reviewedCards,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Todos os cards',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${visibleCards.length} de ${cards.length}',
                    style: const TextStyle(
                      color: DunotsColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (visibleCards.isEmpty)
                const StudyEmptyState(
                  title: 'Nenhum flashcard neste filtro.',
                  detail: 'Abra os filtros para escolher outra situação.',
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

  Widget _buildTopActions() {
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: _createFlashcard,
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
        const SizedBox(width: 4),
        _buildActionsMenu(),
      ],
    );
    if (!widget.showHeader) {
      return Align(alignment: Alignment.centerRight, child: actions);
    }
    return StudyScreenHeader(
      icon: Icons.style_outlined,
      title: 'Flashcards',
      subtitle: 'Revise no seu ritmo.',
      action: actions,
    );
  }

  Widget _buildActionsMenu() {
    return StudyContextMenu<String>(
      tooltip: 'Mais ações dos flashcards',
      onSelected: (value) {
        switch (value) {
          case 'history':
            _openHistory();
          case 'progress':
            _openProgress();
          case 'settings':
            _showReviewSettings();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'history',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.insights_outlined),
            title: Text('Histórico'),
          ),
        ),
        PopupMenuItem(
          value: 'progress',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.trending_up_outlined),
            title: Text('Progresso'),
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune_outlined),
            title: Text('Configurar revisão'),
          ),
        ),
      ],
    );
  }

  Future<void> _showFlashcardFilters({
    required List<String> tags,
    required List<Flashcard> allCards,
    required List<Flashcard> dueCards,
    required List<Flashcard> newCards,
    required List<Flashcard> difficultCards,
    required List<Flashcard> reviewedCards,
  }) async {
    var selectedFilter = _filter;
    var selectedTag = _selectedTag;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          Widget situationChip(String value, String label, int count) {
            return FilterChip(
              selected: selectedFilter == value,
              label: Text('$label ($count)'),
              onSelected: (_) {
                setState(() => _filter = value);
                setSheetState(() => selectedFilter = value);
              },
            );
          }

          Widget tagChip(String value, String label) {
            return FilterChip(
              selected: selectedTag == value,
              label: Text(label),
              onSelected: (_) {
                setState(() => _selectedTag = value);
                setSheetState(() => selectedTag = value);
              },
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext).colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filtrar flashcards',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Situação',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      situationChip('all', 'Todos', allCards.length),
                      situationChip('due', 'Vencidos', dueCards.length),
                      situationChip('new', 'Novos', newCards.length),
                      situationChip(
                        'difficult',
                        'Difíceis',
                        difficultCards.length,
                      ),
                      situationChip(
                        'reviewed',
                        'Revisados',
                        reviewedCards.length,
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Tag',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        tagChip('', 'Todas'),
                        ...tags.map((tag) => tagChip(tag, tag)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Concluir'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _reload() {
    final future = _repository.getAll();
    _cardsFuture = future;
    unawaited(
      future
          .then((cards) {
            if (!mounted || !identical(_cardsFuture, future)) return;
            setState(() => _cardsCache = List.unmodifiable(cards));
          })
          .catchError((_) {}),
    );
    _todaySessionsFuture = _sessionRepository.getForDay(DateTime.now());
  }

  Future<void> _loadPreferences() async {
    final preferences = await _preferencesRepository.get();
    if (!mounted) return;
    setState(() {
      _dailyLimit = preferences.dailyLimit;
      _dailyGoal = preferences.dailyGoal;
      _weeklyGoal = preferences.weeklyGoal;
      _sort = preferences.sort;
      _preferRecommended = preferences.preferRecommended;
      _reminderEnabled = preferences.reminderEnabled;
      _reminderHour = preferences.reminderHour;
      _reminderMinute = preferences.reminderMinute;
    });
  }

  void _changeDailyLimit(int value) {
    setState(() => _dailyLimit = value);
    unawaited(_savePreferences());
  }

  void _changeSort(String value) {
    setState(() => _sort = value);
    unawaited(_savePreferences());
  }

  void _changePreferRecommended(bool value) {
    setState(() => _preferRecommended = value);
    unawaited(_savePreferences());
  }

  Future<void> _showReviewSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Configurar revisão',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sort,
                decoration: const InputDecoration(labelText: 'Ordenar'),
                items: const [
                  DropdownMenuItem(
                    value: 'due',
                    child: Text('Próxima revisão'),
                  ),
                  DropdownMenuItem(value: 'alphabetical', child: Text('A–Z')),
                  DropdownMenuItem(
                    value: 'reviews',
                    child: Text('Mais revisados'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) _changeSort(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dailyLimit,
                decoration: const InputDecoration(
                  labelText: 'Limite por sessão',
                ),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10 cards')),
                  DropdownMenuItem(value: 20, child: Text('20 cards')),
                  DropdownMenuItem(value: 50, child: Text('50 cards')),
                  DropdownMenuItem(value: 0, child: Text('Todos')),
                ],
                onChanged: (value) {
                  if (value != null) _changeDailyLimit(value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Priorizar difíceis'),
                subtitle: const Text('Cards difíceis entram primeiro.'),
                value: _preferRecommended,
                onChanged: _changePreferRecommended,
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Concluir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePreferences() {
    return _preferencesRepository.save(
      FlashcardReviewPreferences(
        dailyLimit: _dailyLimit,
        dailyGoal: _dailyGoal,
        weeklyGoal: _weeklyGoal,
        sort: _sort,
        preferRecommended: _preferRecommended,
        reminderEnabled: _reminderEnabled,
        reminderHour: _reminderHour,
        reminderMinute: _reminderMinute,
      ),
    );
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

  Future<void> _openProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardProgressPage(
          repository: _sessionRepository,
          preferencesRepository: _preferencesRepository,
        ),
      ),
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
    return StudyMetricStrip(
      metrics: [
        StudyMetric(
          value: '$answered',
          label: 'respondidos hoje',
          color: DunotsColors.mint,
        ),
        StudyMetric(
          value: '$good',
          label: 'boa resposta',
          color: DunotsColors.emerald,
        ),
        StudyMetric(
          value: '$difficult',
          label: 'para revisar',
          color: DunotsColors.amber,
        ),
      ],
    );
  }

  Widget _buildRecommendation(
    List<Flashcard> difficultCards,
    List<Flashcard> dueCards,
  ) {
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
    final difficultLabel = difficultCards.length == 1
        ? '1 card difícil'
        : '${difficultCards.length} cards difíceis';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DunotsColors.amber.withValues(alpha: 0.10),
        border: Border.all(color: DunotsColors.amber.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          children: [
            const Icon(
              Icons.tips_and_updates_outlined,
              color: DunotsColors.amber,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                leadingTag == null
                    ? '$difficultLabel merece uma nova revisão.'
                    : '$difficultLabel · priorize $leadingTag.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.25),
              ),
            ),
            TextButton(
              onPressed: () => _openRecommendedSession(
                difficultCards: difficultCards,
                dueCards: dueCards,
              ),
              child: const Text('Revisar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecommendedSession({
    required List<Flashcard> difficultCards,
    required List<Flashcard> dueCards,
  }) async {
    final orderedCards = _buildRecommendedCards(
      difficultCards: difficultCards,
      dueCards: dueCards,
    );
    if (orderedCards.isEmpty || !mounted) return;

    final limit = await showDunotsDrawer<int>(
      context: context,
      builder: (_) => _RecommendedSessionDialog(
        availableCount: orderedCards.length,
        difficultCount: difficultCards.length,
      ),
    );
    if (limit == null || !mounted) return;
    final cards = orderedCards
        .take(limit == 0 ? orderedCards.length : limit)
        .toList(growable: false);
    await _startStudy(cards);
  }

  List<Flashcard> _buildRecommendedCards({
    required List<Flashcard> difficultCards,
    required List<Flashcard> dueCards,
  }) {
    final candidates = <String, Flashcard>{};
    for (final card in difficultCards) {
      candidates[card.id] = card;
    }
    for (final card in dueCards) {
      candidates[card.id] = card;
    }
    final orderedCards = candidates.values.toList()
      ..sort((first, second) {
        final difficultOrder = _difficultyRank(second)
            .compareTo(_difficultyRank(first));
        if (difficultOrder != 0) return difficultOrder;
        return _compareCards(first, second);
      });
    return orderedCards;
  }

  int _difficultyRank(Flashcard card) => card.lastRating == 'difícil' ? 1 : 0;

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
    final card = await showDunotsDrawer<Flashcard>(
      context: context,
      builder: (_) => FlashcardFormDialog(availableMaterials: materials),
    );
    if (card == null || !mounted) return;
    await _save(() => _repository.create(card), addedCard: card);
  }

  Future<void> _editFlashcard(Flashcard card) async {
    final materials = await _loadAvailableMaterials(
      excludedMaterialId: card.id,
    );
    if (!mounted) return;
    final updated = await showDunotsDrawer<Flashcard>(
      context: context,
      builder: (_) =>
          FlashcardFormDialog(initialCard: card, availableMaterials: materials),
    );
    if (updated == null || !mounted) return;
    await _save(() => _repository.update(updated), updatedCard: updated);
  }

  Future<void> _confirmDelete(Flashcard card) async {
    final confirmed = await showDunotsDrawer<bool>(
      context: context,
      builder: (_) => DunotsConfirmDialog(
        title: 'Excluir flashcard?',
        message: 'O flashcard "${card.front}" será removido.',
        confirmLabel: 'Excluir',
      ),
    );
    if (confirmed == true && mounted) {
      await _save(() => _repository.delete(card.id), deletedCardId: card.id);
    }
  }

  Future<void> _save(
    Future<void> Function() action, {
    Flashcard? addedCard,
    Flashcard? updatedCard,
    String? deletedCardId,
  }) async {
    try {
      await action();
      _materialRepository.invalidate();
      if (!mounted) return;

      final current = _cardsCache;
      if (current == null) {
        setState(_reload);
        return;
      }

      final next = current
          .where((card) => card.id != deletedCardId)
          .map((card) => card.id == updatedCard?.id ? updatedCard! : card)
          .toList(growable: true);
      if (addedCard != null) next.add(addedCard);

      setState(() {
        _cardsCache = List.unmodifiable(next);
        _cardsFuture = Future.value(_cardsCache);
      });
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

class _RecommendedSessionDialog extends StatefulWidget {
  final int availableCount;
  final int difficultCount;

  const _RecommendedSessionDialog({
    required this.availableCount,
    required this.difficultCount,
  });

  @override
  State<_RecommendedSessionDialog> createState() =>
      _RecommendedSessionDialogState();
}

class _RecommendedSessionDialogState extends State<_RecommendedSessionDialog> {
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.availableCount >= 10 ? 10 : widget.availableCount;
  }

  List<int> get _options {
    final options = <int>{5, 10, 20, widget.availableCount}
      ..removeWhere((value) => value > widget.availableCount || value <= 0);
    return options.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: 'Montar revisão recomendada',
      subtitle: 'Os cards difíceis aparecem primeiro.',
      icon: Icons.auto_awesome_outlined,
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        children: [
          Text(
            '${widget.availableCount} cards disponíveis · '
            '${widget.difficultCount} classificados como difíceis.',
          ),
          RadioGroup<int>(
            groupValue: _selectedCount,
            onChanged: (value) {
              if (value != null) setState(() => _selectedCount = value);
            },
            child: Column(
              children: _options
                  .map(
                    (option) => RadioListTile<int>(
                      value: option,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        option == widget.availableCount
                            ? 'Todos os cards ($option)'
                            : '$option cards',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedCount),
          child: const Text('Iniciar sessão'),
        ),
      ],
    );
  }
}
