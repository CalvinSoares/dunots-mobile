import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import 'data/challenge_repository.dart';
import 'domain/challenge.dart';

class ChallengeStudyPage extends StatefulWidget {
  final Challenge challenge;
  final ChallengeRepository repository;

  const ChallengeStudyPage({
    super.key,
    required this.challenge,
    required this.repository,
  });

  @override
  State<ChallengeStudyPage> createState() => _ChallengeStudyPageState();
}

class _ChallengeStudyPageState extends State<ChallengeStudyPage> {
  bool _solutionVisible = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    return Scaffold(
      appBar: AppBar(title: const Text('Resolver desafio')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  challenge.notes.isEmpty
                      ? 'Tente resolver o desafio e, quando terminar, confira a solução.'
                      : challenge.notes,
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
                    challenge.solution.isEmpty
                        ? 'Nenhuma solução cadastrada.'
                        : challenge.solution,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Como foi?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_saving)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ratingButton(
                      'novamente',
                      'again',
                      Icons.replay,
                      Colors.red,
                    ),
                    _ratingButton(
                      'difícil',
                      'hard',
                      Icons.trending_down,
                      Colors.deepOrange,
                    ),
                    _ratingButton(
                      'bom',
                      'medium',
                      Icons.check,
                      DunotsColors.amber,
                    ),
                    _ratingButton(
                      'fácil',
                      'easy',
                      Icons.bolt,
                      DunotsColors.mint,
                    ),
                  ],
                ),
            ],
          ],
        ),
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
        challengeId: widget.challenge.id,
        rating: rating,
        reviewedAt: DateTime.now(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a revisão.')),
      );
    }
  }
}
