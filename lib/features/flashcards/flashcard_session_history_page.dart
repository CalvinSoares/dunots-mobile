import 'package:flutter/material.dart';

import '../../core/models/flashcard_session_summary.dart';
import '../../shared/widgets/study_widgets.dart';
import 'data/flashcard_session_repository.dart';

class FlashcardSessionHistoryPage extends StatefulWidget {
  final FlashcardSessionRepository repository;

  const FlashcardSessionHistoryPage({super.key, required this.repository});

  @override
  State<FlashcardSessionHistoryPage> createState() =>
      _FlashcardSessionHistoryPageState();
}

class _FlashcardSessionHistoryPageState
    extends State<FlashcardSessionHistoryPage> {
  int _days = 7;
  late Future<List<FlashcardSessionSummary>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de flashcards'),
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
      body: FutureBuilder<List<FlashcardSessionSummary>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudyLoadingState(message: 'Carregando histórico...');
          }
          if (snapshot.hasError) {
            return StudyErrorState(
              message: 'Não foi possível carregar o histórico.',
              onRetry: () => setState(_reload),
            );
          }
          final sessions = snapshot.data ?? const [];
          if (sessions.isEmpty) {
            return const StudyEmptyState(
              title: 'Nenhuma sessão no período.',
              detail: 'Conclua uma revisão para começar seu histórico.',
              icon: Icons.insights_outlined,
            );
          }
          return _buildContent(sessions);
        },
      ),
    );
  }

  Widget _buildContent(List<FlashcardSessionSummary> sessions) {
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
    final maxCards = sessions
        .map((session) => session.cardCount)
        .reduce((first, second) => first > second ? first : second);

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
            _metric('Sessões', '${sessions.length}'),
            _metric('Cards', '$totalCards'),
            _metric('Difíceis', '$difficult'),
            _metric('Bons', '$good'),
            _metric('Fáceis', '$easy'),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Sessões recentes',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...sessions.map(
          (session) => Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(session.finishedAt),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.cardCount} cards · ${session.answeredCount} respondidos',
                  ),
                  const SizedBox(height: 9),
                  LinearProgressIndicator(value: session.cardCount / maxCards),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    children: [
                      Text('Difíceis: ${session.difficultCount}'),
                      Text('Bons: ${session.goodCount}'),
                      Text('Fáceis: ${session.easyCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 110,
      child: MetricCard(
        label: label,
        value: value,
        icon: Icons.insights_outlined,
        color: const Color(0xFF78B8FF),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · ${date.hour.toString().padLeft(2, '0')}:00';
  }

  void _reload() {
    _sessionsFuture = widget.repository.getRecent(days: _days);
  }
}
