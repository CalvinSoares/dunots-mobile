import 'package:flutter/material.dart';

import '../../core/models/flashcard_review_preferences.dart';
import '../../core/models/flashcard_session_summary.dart';
import '../../shared/widgets/study_widgets.dart';
import 'data/flashcard_review_preferences_repository.dart';
import 'data/flashcard_session_repository.dart';
import 'flashcard_progress_analytics.dart';

class FlashcardProgressPage extends StatefulWidget {
  final FlashcardSessionRepository repository;
  final FlashcardReviewPreferencesRepository? preferencesRepository;

  const FlashcardProgressPage({
    super.key,
    required this.repository,
    this.preferencesRepository,
  });

  @override
  State<FlashcardProgressPage> createState() => _FlashcardProgressPageState();
}

class _FlashcardProgressPageState extends State<FlashcardProgressPage> {
  int _days = 7;
  late final FlashcardReviewPreferencesRepository _preferencesRepository;
  late Future<_ProgressData> _progressFuture;

  @override
  void initState() {
    super.initState();
    _preferencesRepository =
        widget.preferencesRepository ??
        InMemoryFlashcardReviewPreferencesRepository();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso dos flashcards'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (days) => setState(() {
              _days = days;
              _reload();
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Últimos 7 dias')),
              PopupMenuItem(value: 30, child: Text('Últimos 30 dias')),
              PopupMenuItem(value: 90, child: Text('Últimos 90 dias')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<_ProgressData>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudyLoadingState(message: 'Carregando progresso...');
          }
          if (snapshot.hasError) {
            return StudyErrorState(
              message: 'Não foi possível carregar o progresso.',
              onRetry: () => setState(_reload),
            );
          }
          final data = snapshot.data!;
          if (data.sessions.isEmpty) {
            return const StudyEmptyState(
              title: 'Nenhum progresso no período.',
              detail: 'Conclua uma revisão para acompanhar sua evolução.',
              icon: Icons.trending_up_outlined,
            );
          }
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(_ProgressData data) {
    final report = data.report;
    final current = report.currentPeriod;
    final difficult = current.difficult;
    final good = current.good;
    final easy = current.easy;
    final classified = difficult + good + easy;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          'Últimos $_days dias',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metric('Cards', '${current.cards}', Icons.style_outlined),
            _metric('Sessões', '${current.sessions}', Icons.history),
            _metric(
              'Média/sessão',
              current.averagePerSession.toStringAsFixed(1),
              Icons.speed,
            ),
            _metric('Dias ativos', '${current.activeDays}', Icons.event),
          ],
        ),
        const SizedBox(height: 20),
        _buildDailyGoal(data),
        const SizedBox(height: 12),
        _buildWeeklyGoal(data),
        const SizedBox(height: 12),
        _buildComparison(report),
        const SizedBox(height: 24),
        _buildDailyChart(report.days),
        const SizedBox(height: 24),
        _buildWeeklyChart(report.weeks),
        const SizedBox(height: 24),
        const Text(
          'Distribuição das classificações',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _classificationRow(
          label: 'Difíceis',
          value: difficult,
          total: classified,
          color: Theme.of(context).colorScheme.error,
        ),
        _classificationRow(
          label: 'Bons',
          value: good,
          total: classified,
          color: Theme.of(context).colorScheme.primary,
        ),
        _classificationRow(
          label: 'Fáceis',
          value: easy,
          total: classified,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Detalhamento por dia',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...report.days.reversed.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 82, child: Text(_formatDate(day.day))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: report.currentPeriod.cards == 0
                        ? 0
                        : day.cards / report.currentPeriod.cards,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 30, child: Text('${day.cards}')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGoal(_ProgressData data) {
    final goal = data.preferences.weeklyGoal;
    final completed = data.report.currentWeek.cards;
    final progress = goal == 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);
    final reached = completed >= goal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reached ? Icons.emoji_events_outlined : Icons.flag_outlined,
                  color: reached
                      ? Colors.amber.shade700
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Meta semanal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => _changeWeeklyGoal(data.preferences),
                  child: const Text('Definir'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reached
                  ? 'Meta concluída: $completed/$goal cards nesta semana.'
                  : 'Esta semana: $completed/$goal cards revisados.',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 8),
            Text(
              '${data.report.currentWeek.activeDays} dias ativos · '
              '${data.report.currentWeek.sessions} sessões',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(FlashcardProgressReport report) {
    final change = report.currentPeriod.changeFrom(report.previousPeriod);
    final changeLabel = change == null
        ? 'sem base anterior'
        : change == 0
        ? 'igual ao período anterior'
        : '${change > 0 ? '+' : ''}${(change * 100).round()}% vs. período anterior';
    final changeColor = change == null || change == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : change > 0
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativo de evolução',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _comparisonValue(
                    'Período atual',
                    '${report.currentPeriod.cards} cards',
                  ),
                ),
                Expanded(
                  child: _comparisonValue(
                    'Período anterior',
                    '${report.previousPeriod.cards} cards',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              changeLabel,
              style: TextStyle(color: changeColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Retenção atual: ${(report.currentPeriod.retentionRate * 100).round()}% '
              '· anterior: ${(report.previousPeriod.retentionRate * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildDailyChart(List<FlashcardDaySummary> days) {
    final maxCards = days.fold<int>(
      1,
      (maximum, day) => day.cards > maximum ? day.cards : maximum,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atividade por dia',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: days
                    .map(
                      (day) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 20,
                                child: FittedBox(
                                  child: Text(
                                    '${day.cards}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: day.cards / maxCards,
                                    widthFactor: .72,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(_weekday(day.day)),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<FlashcardWeekSummary> weeks) {
    final maxCards = weeks.fold<int>(
      1,
      (maximum, week) => week.cards > maximum ? week.cards : maximum,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolução semanal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: weeks
                    .map(
                      (week) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text('${week.cards}'),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: week.cards / maxCards,
                                    widthFactor: .58,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: week == weeks.last
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: .55),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(_formatShortDate(week.start)),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cada barra representa uma semana iniciada na segunda-feira.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return SizedBox(
      width: 122,
      child: MetricCard(
        label: label,
        value: value,
        icon: icon,
        color: const Color(0xFF78B8FF),
      ),
    );
  }

  Widget _buildDailyGoal(_ProgressData data) {
    final goal = data.preferences.dailyGoal;
    final completed = data.todaySessions.fold<int>(
      0,
      (total, session) => total + session.cardCount,
    );
    final progress = goal == 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);
    final reached = completed >= goal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reached ? Icons.check_circle : Icons.flag_outlined,
                  color: reached
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Meta diária',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => _changeDailyGoal(data.preferences),
                  child: const Text('Alterar'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reached
                  ? 'Meta concluída: $completed/$goal cards.'
                  : 'Hoje: $completed/$goal cards revisados.',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, minHeight: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _changeDailyGoal(FlashcardReviewPreferences current) async {
    final goal = await showDialog<int>(
      context: context,
      builder: (_) => _DailyGoalDialog(currentGoal: current.dailyGoal),
    );
    if (goal == null || !mounted) return;
    await _preferencesRepository.save(current.copyWith(dailyGoal: goal));
    if (mounted) setState(_reload);
  }

  Future<void> _changeWeeklyGoal(FlashcardReviewPreferences current) async {
    final goal = await showDialog<int>(
      context: context,
      builder: (_) => _WeeklyGoalDialog(currentGoal: current.weeklyGoal),
    );
    if (goal == null || !mounted) return;
    await _preferencesRepository.save(current.copyWith(weeklyGoal: goal));
    if (mounted) setState(_reload);
  }

  Widget _classificationRow({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 82, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              color: color,
              minHeight: 10,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text('$value (${(ratio * 100).round()}%)'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _weekday(DateTime date) {
    const labels = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    return labels[date.weekday - 1];
  }

  void _reload() {
    _progressFuture = _loadProgress();
  }

  Future<_ProgressData> _loadProgress() async {
    final historyDays = _days < 28 ? 28 : _days * 2;
    final sessions = await widget.repository.getRecent(days: historyDays);
    final todaySessions = await widget.repository.getForDay(DateTime.now());
    final preferences = await _preferencesRepository.get();
    return _ProgressData(
      sessions: sessions,
      todaySessions: todaySessions,
      preferences: preferences,
      report: buildFlashcardProgressReport(
        sessions,
        reference: DateTime.now(),
        windowDays: _days,
      ),
    );
  }
}

class _ProgressData {
  final List<FlashcardSessionSummary> sessions;
  final List<FlashcardSessionSummary> todaySessions;
  final FlashcardReviewPreferences preferences;
  final FlashcardProgressReport report;

  const _ProgressData({
    required this.sessions,
    required this.todaySessions,
    required this.preferences,
    required this.report,
  });
}

class _DailyGoalDialog extends StatelessWidget {
  final int currentGoal;

  const _DailyGoalDialog({required this.currentGoal});

  @override
  Widget build(BuildContext context) {
    const options = [5, 10, 20, 50, 100];
    return AlertDialog(
      title: const Text('Definir meta diária'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Escolha quantos cards quer revisar por dia.'),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: currentGoal,
            onChanged: (value) {
              if (value != null) Navigator.of(context).pop(value);
            },
            child: Column(
              children: options
                  .map(
                    (option) => RadioListTile<int>(
                      value: option,
                      title: Text('$option cards por dia'),
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
      ],
    );
  }
}

class _WeeklyGoalDialog extends StatelessWidget {
  final int currentGoal;

  const _WeeklyGoalDialog({required this.currentGoal});

  @override
  Widget build(BuildContext context) {
    const options = [25, 50, 100, 150, 200, 300];
    return AlertDialog(
      title: const Text('Definir meta semanal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Escolha quantos cards quer revisar por semana.'),
          ),
          const SizedBox(height: 8),
          RadioGroup<int>(
            groupValue: currentGoal,
            onChanged: (value) {
              if (value != null) Navigator.of(context).pop(value);
            },
            child: Column(
              children: options
                  .map(
                    (option) => RadioListTile<int>(
                      value: option,
                      title: Text('$option cards por semana'),
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
      ],
    );
  }
}
