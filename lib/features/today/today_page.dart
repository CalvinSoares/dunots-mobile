import 'package:flutter/material.dart';

import '../../core/models/flashcard.dart';
import '../../core/models/flashcard_review_preferences.dart';
import '../flashcards/data/flashcard_repository.dart';
import '../flashcards/data/flashcard_review_preferences_repository.dart';
import '../flashcards/data/flashcard_session_repository.dart';
import '../questions/data/question_repository.dart';
import '../quizzes/data/quiz_attempt_repository.dart';
import '../quizzes/domain/quiz_attempt.dart';
import '../quizzes/quiz_attempt_page.dart';
import '../roadmaps/data/study_track_repository.dart';
import '../roadmaps/domain/study_track.dart';
import '../../shared/widgets/study_widgets.dart';
import '../../core/notifications/local_notification_service.dart';

class TodayPage extends StatefulWidget {
  final FlashcardRepository? flashcardRepository;
  final FlashcardSessionRepository? flashcardSessionRepository;
  final FlashcardReviewPreferencesRepository?
  flashcardReviewPreferencesRepository;
  final StudyTrackRepository? trackRepository;
  final QuestionRepository? questionRepository;
  final QuizAttemptRepository? attemptRepository;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenQuestions;
  final LocalNotificationService? localNotificationService;

  const TodayPage({
    super.key,
    this.flashcardRepository,
    this.flashcardSessionRepository,
    this.flashcardReviewPreferencesRepository,
    this.trackRepository,
    this.questionRepository,
    this.attemptRepository,
    this.onOpenFlashcards,
    this.onOpenQuestions,
    this.localNotificationService,
  });

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<_TodayData> _dataFuture;
  late final LocalNotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService =
        widget.localNotificationService ?? const NoopLocalNotificationService();
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
    await _notificationService.syncDailyFlashcardReminder(
      preferences: preferences,
      completedToday: completedToday,
      dueCount: dueCount,
    );
    return _TodayData(
      cards: cards,
      tracks: tracks,
      inProgress: inProgress,
      dueCount: dueCount,
      completedToday: completedToday,
      preferences: preferences,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const StudyLoadingState(message: 'Carregando seu mural...');
        }
        if (snapshot.hasError) {
          return StudyErrorState(
            message: 'Não foi possível carregar o mural.',
            onRetry: () => setState(() {
              _dataFuture = _loadData();
            }),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const StudyEmptyState(
            title: 'Nenhum dado disponível.',
            detail: 'Tente novamente para atualizar seu mural.',
            icon: Icons.dashboard_outlined,
          );
        }
        return _buildContent(context, data);
      },
    );
  }

  Widget _buildContent(BuildContext context, _TodayData data) {
    final firstAttempt = data.inProgress.firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DunotsBrand(),
                  const SizedBox(height: 28),
                  Text(
                    'seu caderno de estudos',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: const Color(0xFFB6B7AD)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vamos avançar um pouco hoje?',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 22),
                  ReviewCard(
                    count: data.cards.length,
                    onPressed: widget.onOpenFlashcards,
                  ),
                  if (data.preferences.reminderEnabled &&
                      data.completedToday < data.preferences.dailyGoal) ...[
                    const SizedBox(height: 14),
                    _buildReminder(context, data),
                  ],
                  const SizedBox(height: 18),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: 'flashcards',
                            value: '${data.cards.length}',
                            icon: Icons.style_outlined,
                            color: const Color(0xFF78B8FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'trilhas ativas',
                            value: '${data.tracks.length}',
                            icon: Icons.route_outlined,
                            color: const Color(0xFFB79BFF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'simulados em andamento',
                            value: '${data.inProgress.length}',
                            icon: Icons.assignment_outlined,
                            color: const Color(0xFFFFC857),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                label: 'flashcards',
                                value: '${data.cards.length}',
                                icon: Icons.style_outlined,
                                color: const Color(0xFF78B8FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricCard(
                                label: 'trilhas ativas',
                                value: '${data.tracks.length}',
                                icon: Icons.route_outlined,
                                color: const Color(0xFFB79BFF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MetricCard(
                          label: 'simulados em andamento',
                          value: '${data.inProgress.length}',
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFFFFC857),
                        ),
                      ],
                    ),
                  const SizedBox(height: 26),
                  Text(
                    'acesso rápido',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  QuickAction(
                    icon: Icons.style_outlined,
                    title: 'Abrir flashcards',
                    subtitle: '${data.cards.length} cartões cadastrados',
                    color: const Color(0xFFFF7168),
                    onTap: widget.onOpenFlashcards,
                  ),
                  const SizedBox(height: 10),
                  QuickAction(
                    icon: Icons.assignment_outlined,
                    title: firstAttempt == null
                        ? 'Montar simulado'
                        : 'Continuar simulado',
                    subtitle: firstAttempt == null
                        ? 'Escolha questões para começar'
                        : firstAttempt.title,
                    color: const Color(0xFFFFC857),
                    onTap: firstAttempt == null
                        ? widget.onOpenQuestions
                        : () => _openAttempt(firstAttempt),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'trilhas em andamento',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (data.tracks.isEmpty)
                    const ExampleListTile(
                      title: 'Nenhuma trilha criada',
                      detail: 'Crie uma trilha para organizar seus estudos.',
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
      },
    );
  }

  Widget _buildReminder(BuildContext context, _TodayData data) {
    final remaining = data.preferences.dailyGoal - data.completedToday;
    final schedule = _formatTime(
      data.preferences.reminderHour,
      data.preferences.reminderMinute,
    );
    final detail = data.dueCount > 0
        ? '${data.dueCount} card(s) aguardam revisão. Faltam $remaining para a meta. '
              'Lembrete configurado para $schedule.'
        : 'Faltam $remaining card(s) para concluir sua meta. '
              'Lembrete configurado para $schedule.';
    return Card(
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lembrete de revisão',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(detail),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onOpenFlashcards,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Revisar agora'),
                        ),
                        TextButton.icon(
                          onPressed: () => _configureReminder(data.preferences),
                          icon: const Icon(Icons.schedule_outlined),
                          label: const Text('Configurar horário'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _configureReminder(FlashcardReviewPreferences current) async {
    final updated = await showDialog<FlashcardReviewPreferences>(
      context: context,
      builder: (_) => _ReminderSettingsDialog(preferences: current),
    );
    if (updated == null || !mounted) return;
    final repository = widget.flashcardReviewPreferencesRepository;
    if (repository == null) return;
    await repository.save(updated);
    if (updated.reminderEnabled) {
      await _notificationService.requestPermission();
    }
    if (mounted) {
      setState(() {
        _dataFuture = _loadData();
      });
    }
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openAttempt(QuizAttempt attempt) async {
    final questionRepository = widget.questionRepository;
    final attemptRepository = widget.attemptRepository;
    if (questionRepository == null || attemptRepository == null || !mounted) {
      widget.onOpenQuestions?.call();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAttemptPage(
          attempt: attempt,
          questionRepository: questionRepository,
          attemptRepository: attemptRepository,
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

  const _TodayData({
    required this.cards,
    required this.tracks,
    required this.inProgress,
    required this.dueCount,
    required this.completedToday,
    required this.preferences,
  });
}

class _ReminderSettingsDialog extends StatefulWidget {
  final FlashcardReviewPreferences preferences;

  const _ReminderSettingsDialog({required this.preferences});

  @override
  State<_ReminderSettingsDialog> createState() =>
      _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<_ReminderSettingsDialog> {
  late bool _enabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _enabled = widget.preferences.reminderEnabled;
    _time = TimeOfDay(
      hour: widget.preferences.reminderHour,
      minute: widget.preferences.reminderMinute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar lembrete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ativar lembrete'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Horário'),
            subtitle: Text(_time.format(context)),
            enabled: _enabled,
            onTap: _enabled ? _pickTime : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.preferences.copyWith(
              reminderEnabled: _enabled,
              reminderHour: _time.hour,
              reminderMinute: _time.minute,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }
}
