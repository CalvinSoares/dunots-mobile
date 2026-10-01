import 'package:flutter/material.dart';

import 'data/challenge_repository.dart';
import 'domain/challenge.dart';

class ChallengeStudySessionPage extends StatefulWidget {
  final List<Challenge> challenges;
  final ChallengeRepository repository;

  const ChallengeStudySessionPage({
    super.key,
    required this.challenges,
    required this.repository,
  });

  @override
  State<ChallengeStudySessionPage> createState() =>
      _ChallengeStudySessionPageState();
}

class _ChallengeStudySessionPageState extends State<ChallengeStudySessionPage> {
  int _index = 0;
  int _again = 0;
  int _hard = 0;
  int _medium = 0;
  int _easy = 0;
  bool _solutionVisible = false;
  bool _saving = false;
  bool _finished = false;

  Challenge get _current => widget.challenges[_index];

  @override
  Widget build(BuildContext context) {
    if (widget.challenges.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sessão de desafios')),
        body: const Center(child: Text('Nenhum desafio nesta sessão.')),
      );
    }
    if (_finished) return _buildFinished(context);

    final total = widget.challenges.length;
    final progress = (_index + (_solutionVisible ? 1 : 0)) / total;
    return Scaffold(
      appBar: AppBar(
        title: Text('Desafios · ${_index + 1}/$total'),
        actions: [
          IconButton(
            tooltip: 'Sair da sessão',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: 24),
          Text(
            _current.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(_current.difficulty.name)),
              ..._current.tags.map((tag) => Chip(label: Text(tag))),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _current.notes.isEmpty
                    ? 'Resolva o desafio antes de revelar a solução.'
                    : _current.notes,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_solutionVisible)
            FilledButton.icon(
              onPressed: () => setState(() => _solutionVisible = true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Mostrar solução'),
            )
          else ...[
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _current.solution.isEmpty
                      ? 'Nenhuma solução cadastrada.'
                      : _current.solution,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Como foi?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (_saving)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ratingButton('novamente', 'again', Icons.replay, Colors.red),
                  _ratingButton(
                    'difícil',
                    'hard',
                    Icons.trending_down,
                    Colors.deepOrange,
                  ),
                  _ratingButton('bom', 'medium', Icons.check, Colors.orange),
                  _ratingButton('fácil', 'easy', Icons.bolt, Colors.green),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _ratingButton(
    String label,
    String rating,
    IconData icon,
    Color color,
  ) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: color),
      onPressed: () => _saveReview(rating),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<void> _saveReview(String rating) async {
    setState(() => _saving = true);
    try {
      await widget.repository.recordReview(
        challengeId: _current.id,
        rating: rating,
        reviewedAt: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        switch (rating) {
          case 'again':
            _again++;
          case 'hard':
            _hard++;
          case 'medium':
            _medium++;
          case 'easy':
            _easy++;
        }
        _saving = false;
        if (_index == widget.challenges.length - 1) {
          _finished = true;
        } else {
          _index++;
          _solutionVisible = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a revisão.')),
      );
    }
  }

  Widget _buildFinished(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessão concluída')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Sessão concluída',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${widget.challenges.length} desafios revisados.'),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Chip(label: Text('Novamente: $_again')),
                  Chip(label: Text('Difícil: $_hard')),
                  Chip(label: Text('Bom: $_medium')),
                  Chip(label: Text('Fácil: $_easy')),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Voltar aos desafios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
