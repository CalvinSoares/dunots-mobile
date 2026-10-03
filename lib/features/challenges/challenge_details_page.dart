import 'package:flutter/material.dart';

import 'data/challenge_repository.dart';
import 'domain/challenge.dart';
import 'domain/challenge_review.dart';
import 'challenge_study_page.dart';

class ChallengeDetailsPage extends StatefulWidget {
  final Challenge challenge;
  final ChallengeRepository repository;

  const ChallengeDetailsPage({
    super.key,
    required this.challenge,
    required this.repository,
  });

  @override
  State<ChallengeDetailsPage> createState() => _ChallengeDetailsPageState();
}

class _ChallengeDetailsPageState extends State<ChallengeDetailsPage> {
  late Challenge _challenge;
  late Future<List<ChallengeReview>> _history;

  @override
  void initState() {
    super.initState();
    _challenge = widget.challenge;
    _reloadHistory();
  }

  void _reloadHistory() {
    _history = widget.repository.getReviewHistory(_challenge.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do desafio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              _challenge.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_challenge.difficulty.name)),
                if (_challenge.problemId.isNotEmpty)
                  Chip(label: Text('#${_challenge.problemId}')),
                ..._challenge.tags.map((tag) => Chip(label: Text(tag))),
              ],
            ),
            const SizedBox(height: 20),
            _InfoCard(
              title: 'Progresso',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revisões: ${_challenge.repetitions}'),
                  Text('Intervalo atual: ${_challenge.interval} dia(s)'),
                  Text(
                    _challenge.dueAt == null
                        ? 'Ainda não revisado'
                        : 'Próxima revisão: ${_formatDate(_challenge.dueAt!)}',
                  ),
                ],
              ),
            ),
            if (_challenge.strategy.isNotEmpty)
              _InfoCard(title: 'Estratégia', child: Text(_challenge.strategy)),
            if (_challenge.notes.isNotEmpty)
              _InfoCard(title: 'Anotações', child: Text(_challenge.notes)),
            if (_challenge.solution.isNotEmpty)
              _InfoCard(
                title: 'Solução cadastrada',
                child: Text('A solução será exibida durante a resolução.'),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _startStudy,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resolver desafio'),
            ),
            const SizedBox(height: 24),
            Text(
              'Histórico de revisões',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<ChallengeReview>>(
              future: _history,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Não foi possível carregar o histórico.');
                }
                final reviews = snapshot.data ?? const <ChallengeReview>[];
                if (reviews.isEmpty) {
                  return const Text('Nenhuma revisão registrada.');
                }
                return Column(
                  children: reviews
                      .map(
                        (review) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text(_ratingLabel(review.rating)),
                          subtitle: Text(
                            '${_formatDate(review.reviewedAt)} · próximo intervalo: '
                            '${review.nextInterval} dia(s)',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startStudy() async {
    final reviewed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChallengeStudyPage(
          challenge: _challenge,
          repository: widget.repository,
        ),
      ),
    );
    if (reviewed != true || !mounted) return;
    final updated = (await widget.repository.getAll())
        .where((item) => item.id == _challenge.id)
        .firstOrNull;
    if (updated == null) return;
    setState(() {
      _challenge = updated;
      _reloadHistory();
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _ratingLabel(String rating) => switch (rating) {
    'again' => 'novamente',
    'hard' => 'difícil',
    'medium' => 'bom',
    'easy' => 'fácil',
    _ => rating,
  };
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
