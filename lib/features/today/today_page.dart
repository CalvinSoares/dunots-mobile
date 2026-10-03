import 'package:flutter/material.dart';

import '../../shared/widgets/dunots_modal.dart';

import '../../core/models/flashcard.dart';
import '../../core/models/flashcard_review_preferences.dart';
import '../flashcards/data/flashcard_repository.dart';
import '../flashcards/data/flashcard_review_preferences_repository.dart';
import '../flashcards/data/flashcard_session_repository.dart';
import '../study/data/study_phase_repository.dart';
import '../study/domain/study_phase.dart';
import '../study/study_phase_details_page.dart';
import '../study/study_phase_form_dialog.dart';
import '../quizzes/data/quiz_attempt_repository.dart';
import '../quizzes/domain/quiz_attempt.dart';
import '../roadmaps/data/study_track_repository.dart';
import '../roadmaps/domain/study_track.dart';
import '../../shared/widgets/study_widgets.dart';
import '../../app/dunots_theme.dart';
import '../../core/notifications/local_notification_service.dart';

class TodayPage extends StatefulWidget {
  final bool showHeader;
  final FlashcardRepository? flashcardRepository;
  final FlashcardSessionRepository? flashcardSessionRepository;
  final FlashcardReviewPreferencesRepository?
  flashcardReviewPreferencesRepository;
  final StudyTrackRepository? trackRepository;
  final QuizAttemptRepository? attemptRepository;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenTracks;
  final LocalNotificationService? localNotificationService;
  final StudyPhaseRepository? phaseRepository;

  const TodayPage({
    super.key,
    this.showHeader = true,
    this.flashcardRepository,
    this.flashcardSessionRepository,
    this.flashcardReviewPreferencesRepository,
    this.trackRepository,
    this.attemptRepository,
    this.onOpenFlashcards,
    this.onOpenTracks,
    this.localNotificationService,
    this.phaseRepository,
  });

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<_TodayData> _dataFuture;
  late final LocalNotificationService _notificationService;
  late final StudyPhaseRepository _phaseRepository;

  @override
  void initState() {
    super.initState();
    _notificationService =
        widget.localNotificationService ?? const NoopLocalNotificationService();
    _phaseRepository = widget.phaseRepository ?? InMemoryStudyPhaseRepository();
    _dataFuture = _loadData();
  }

  Future<_TodayData> _loadData() async {
    final cards =
        await (widget.flashcardRepository ?? InMemoryFlashcardRepository())
            .getAll();
    final now = DateTime.now();
    final dueCount = cards.where((card) => card.isDueAt(now)).length;
    final sessions =
        await (widget.flashcardSessionRepository ??
                InMemoryFlashcardSessionRepository())
            .getForDay(now);
    final preferences =
        await (widget.flashcardReviewPreferencesRepository ??
                InMemoryFlashcardReviewPreferencesRepository())
            .get();
    final tracks =
        await (widget.trackRepository ?? InMemoryStudyTrackRepository())
            .getAll();
    final phases = await _phaseRepository.getAll();
    final attempts =
        await (widget.attemptRepository ?? InMemoryQuizAttemptRepository())
            .getAll();
    final inProgress = attempts
        .where((attempt) => attempt.status == QuizAttemptStatus.inProgress)
        .toList(growable: false);
    final completedToday = sessions.fold<int>(
      0,
      (total, session) => total + session.cardCount,
    );
    // Notificações são um recurso auxiliar. Uma falha do plugin (permissão,
    // timezone ou configuração do Android) não pode impedir o mural de abrir.
    try {
      await _notificationService.syncDailyFlashcardReminder(
        preferences: preferences,
        completedToday: completedToday,
        dueCount: dueCount,
      );
    } catch (_) {
      // O lembrete continua opcional; o restante dos dados permanece visível.
    }
    return _TodayData(
      cards: cards,
      tracks: tracks,
      inProgress: inProgress,
      dueCount: dueCount,
      completedToday: completedToday,
      preferences: preferences,
      phases: phases,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: StudyLoadingState(message: 'Carregando seu mural...'),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: StudyErrorState(
              message: 'Não foi possível carregar o mural.',
              onRetry: () => setState(() {
                _dataFuture = _loadData();
              }),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(
            child: StudyEmptyState(
              title: 'Nenhum dado disponível.',
              detail: 'Tente novamente para atualizar seu mural.',
              icon: Icons.dashboard_outlined,
            ),
          );
        }
        return _buildContent(context, data);
      },
    );
  }

  Widget _buildContent(BuildContext context, _TodayData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) ...[
                StudyScreenHeader(
                  icon: Icons.today_outlined,
                  title: 'Hoje',
                  subtitle: 'Sua próxima sessão e o progresso do dia.',
                ),
                const SizedBox(height: 20),
              ],
              _buildStudyFocus(context, data),
              const SizedBox(height: 14),
              _buildTodaySummary(context, data),
              const SizedBox(height: 26),
              _buildSectionHeader(
                context,
                title: 'Fases de estudo',
                action: Tooltip(
                  message: 'Nova fase de estudo',
                  child: TextButton.icon(
                    onPressed: () => _createPhase(data),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nova'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (data.phases.isEmpty)
                ExampleListTile(
                  title: 'Nenhuma fase criada',
                  detail: 'Agrupe flashcards para estudar por objetivo.',
                  onTap: () => _createPhase(data),
                )
              else
                ...data.phases.asMap().entries.map(
                  (entry) =>
                      _buildPhaseCard(context, data, entry.value, entry.key),
                ),
              const SizedBox(height: 26),
              _buildSectionHeader(context, title: 'Trilhas em andamento'),
              const SizedBox(height: 10),
              if (data.tracks.isEmpty)
                ExampleListTile(
                  title: 'Nenhuma trilha criada',
                  detail: 'Crie uma trilha para organizar seus estudos.',
                  onTap: widget.onOpenTracks,
                )
              else
                ...data.tracks
                    .take(3)
                    .map(
                      (track) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProgressListTile(track: track),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyFocus(BuildContext context, _TodayData data) {
    final hasReviews = data.dueCount > 0;
    return StudyFocusCard(
      eyebrow: hasReviews ? 'Próxima ação' : 'Tudo em dia',
      eyebrowIcon: hasReviews
          ? Icons.play_circle_outline
          : Icons.check_circle_outline,
      title: hasReviews
          ? 'Revisar ${data.dueCount} flashcards'
          : 'Sua revisão está em dia',
      detail: hasReviews
          ? '${data.completedToday} revisados hoje · meta ${data.preferences.dailyGoal}.'
          : 'Abra seus flashcards para continuar avançando no seu ritmo.',
      actionIcon: Icons.play_arrow_rounded,
      actionLabel: hasReviews ? 'Estudar agora' : 'Abrir flashcards',
      onPressed: widget.onOpenFlashcards,
    );
  }

  Widget _buildTodaySummary(BuildContext context, _TodayData data) {
    return StudyMetricStrip(
      metrics: [
        StudyMetric(
          value: '${data.dueCount}',
          label: 'pendentes',
          color: DunotsColors.amber,
        ),
        StudyMetric(
          value: '${data.completedToday}',
          label: 'concluídos hoje',
          color: DunotsColors.mint,
        ),
        StudyMetric(
          value: '${data.tracks.length}',
          label: 'trilhas',
          color: DunotsColors.purple,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    Widget? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?action,
      ],
    );
  }

  Widget _buildPhaseCard(
    BuildContext context,
    _TodayData data,
    StudyPhase phase,
    int index,
  ) {
    final progress = phase.progress(flashcards: data.cards);
    final completed = phase.completedItems(flashcards: data.cards);
    final percent = (progress * 100).round();
    return Semantics(
      button: true,
      label:
          'Fase ${phase.title}. $completed de ${phase.totalItems} concluídos. $percent por cento.',
      hint: 'Toque para abrir a fase.',
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openPhase(phase),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DunotsColors.mint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    color: DunotsColors.mint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$completed/${phase.totalItems} concluídos · ${phase.flashcardIds.length} cards',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DunotsColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: DunotsColors.mint,
                          backgroundColor: DunotsColors.border,
                        ),
                      ),
                    ],
                  ),
                ),
                StudyContextMenu<String>(
                  tooltip: 'Ações da fase',
                  onSelected: (value) {
                    if (value == 'up') _movePhase(data, index, -1);
                    if (value == 'down') _movePhase(data, index, 1);
                  },
                  itemBuilder: (context) => [
                    if (index > 0)
                      const PopupMenuItem(
                        value: 'up',
                        child: Text('Mover para cima'),
                      ),
                    if (index < data.phases.length - 1)
                      const PopupMenuItem(
                        value: 'down',
                        child: Text('Mover para baixo'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _movePhase(_TodayData data, int index, int delta) async {
    final targetIndex = index + delta;
    if (targetIndex < 0 || targetIndex >= data.phases.length) return;
    final orderedIds = data.phases.map((phase) => phase.id).toList();
    final moved = orderedIds.removeAt(index);
    orderedIds.insert(targetIndex, moved);
    await _phaseRepository.reorder(orderedIds);
    if (mounted) {
      setState(() {
        _dataFuture = _loadData();
      });
    }
  }

  Future<void> _createPhase(_TodayData data) async {
    final phase = await showDunotsDrawer<StudyPhase>(
      context: context,
      builder: (_) => StudyPhaseFormDialog(flashcards: data.cards),
    );
    if (phase == null) return;
    await _phaseRepository.create(
      phase.copyWith(sortOrder: data.phases.length),
    );
    if (mounted) {
      setState(() {
        _dataFuture = _loadData();
      });
    }
  }

  Future<void> _openPhase(StudyPhase phase) async {
    final flashcardRepository =
        widget.flashcardRepository ?? InMemoryFlashcardRepository();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyPhaseDetailsPage(
          phase: phase,
          phaseRepository: _phaseRepository,
          flashcardRepository: flashcardRepository,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _dataFuture = _loadData();
      });
    }
  }
}

class _TodayData {
  final List<Flashcard> cards;
  final List<StudyTrack> tracks;
  final List<QuizAttempt> inProgress;
  final int dueCount;
  final int completedToday;
  final FlashcardReviewPreferences preferences;
  final List<StudyPhase> phases;

  const _TodayData({
    required this.cards,
    required this.tracks,
    required this.inProgress,
    required this.dueCount,
    required this.completedToday,
    required this.preferences,
    required this.phases,
  });
}
