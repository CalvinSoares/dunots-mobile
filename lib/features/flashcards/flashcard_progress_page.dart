import 'package:flutter/material.dart';

import '../../core/models/flashcard_review_preferences.dart';
import '../../core/models/flashcard_session_summary.dart';
import '../../shared/widgets/study_widgets.dart';
import 'data/flashcard_review_preferences_repository.dart';
import 'data/flashcard_session_repository.dart';

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
    final sessions = data.sessions;
    final totalCards = sessions.fold<int>(
      0,
      (total, session) => total + session.cardCount,
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
    final classified = difficult + good + easy;
    final average = totalCards / sessions.length;
    final dailyTotals = _dailyTotals(sessions);
    final maxDaily = dailyTotals.values.reduce(
      (first, second) => first > second ? first : second,
    );

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
            _metric('Cards', '$totalCards', Icons.style_outlined),
            _metric('Sessões', '${sessions.length}', Icons.history),
            _metric('Média/sessão', average.toStringAsFixed(1), Icons.speed),
          ],
        ),
        const SizedBox(height: 20),
        _buildDailyGoal(data),
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
          'Atividade por dia',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...dailyTotals.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 82, child: Text(_formatDate(entry.key))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: entry.value / maxDaily,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 30, child: Text('${entry.value}')),
              ],
            ),
          ),
        ),
      ],
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
    await _preferencesRepository.save(
      FlashcardReviewPreferences(
        dailyLimit: current.dailyLimit,
        dailyGoal: goal,
        sort: current.sort,
        preferRecommended: current.preferRecommended,
      ),
    );
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

  Map<DateTime, int> _dailyTotals(List<FlashcardSessionSummary> sessions) {
    final totals = <DateTime, int>{};
    for (final session in sessions) {
      final day = DateTime(
        session.finishedAt.year,
        session.finishedAt.month,
        session.finishedAt.day,
      );
      totals.update(
        day,
        (value) => value + session.cardCount,
        ifAbsent: () => session.cardCount,
      );
    }
    final entries = totals.entries.toList()
      ..sort((first, second) => second.key.compareTo(first.key));
    return Map.fromEntries(entries);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  void _reload() {
    _progressFuture = _loadProgress();
  }

  Future<_ProgressData> _loadProgress() async {
    final sessions = await widget.repository.getRecent(days: _days);
    final todaySessions = await widget.repository.getForDay(DateTime.now());
    final preferences = await _preferencesRepository.get();
    return _ProgressData(
      sessions: sessions,
      todaySessions: todaySessions,
      preferences: preferences,
    );
  }
}

class _ProgressData {
  final List<FlashcardSessionSummary> sessions;
  final List<FlashcardSessionSummary> todaySessions;
  final FlashcardReviewPreferences preferences;

  const _ProgressData({
    required this.sessions,
    required this.todaySessions,
    required this.preferences,
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
