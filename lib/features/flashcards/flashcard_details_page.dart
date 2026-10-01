import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';

import '../questions/data/question_repository.dart';
import '../questions/question_details_page.dart';
import '../roadmaps/data/study_material_repository.dart';
import '../roadmaps/domain/study_material.dart';
import 'data/flashcard_repository.dart';

class FlashcardDetailsPage extends StatelessWidget {
  final Flashcard card;
  final FlashcardRepository? flashcardRepository;
  final QuestionRepository? questionRepository;
  final StudyMaterialRepository? materialRepository;

  const FlashcardDetailsPage({
    super.key,
    required this.card,
    this.flashcardRepository,
    this.questionRepository,
    this.materialRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do flashcard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pergunta',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.front,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 28),
            Text(
              'Resposta',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  card.back,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como estudado'),
              ),
            ),
            if (card.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Tags',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: card.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
            ],
            if (card.code.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Código',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      card.code,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
            if (card.linkedMaterialIds.isNotEmpty &&
                materialRepository != null) ...[
              const SizedBox(height: 24),
              Text(
                'Materiais relacionados',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<StudyMaterial>>(
                future: materialRepository!.getAll(),
                builder: (context, snapshot) {
                  final materials = (snapshot.data ?? const <StudyMaterial>[])
                      .where(
                        (material) =>
                            card.linkedMaterialIds.contains(material.id),
                      )
                      .toList(growable: false);
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LinearProgressIndicator();
                  }
                  if (materials.isEmpty) {
                    return const Text(
                      'Os materiais vinculados não estão disponíveis.',
                    );
                  }
                  return Column(
                    children: materials
                        .map(
                          (material) => Card(
                            child: ListTile(
                              leading: Icon(_materialIcon(material.type)),
                              title: Text(material.title),
                              subtitle: Text(material.subtitle),
                              trailing: const Icon(Icons.open_in_new),
                              onTap: () => _openMaterial(context, material),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openMaterial(
    BuildContext context,
    StudyMaterial material,
  ) async {
    switch (material.type) {
      case StudyMaterialType.question:
        final repository = questionRepository;
        if (repository == null) return;
        final question = (await repository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (question != null && context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuestionDetailsPage(question: question),
            ),
          );
        }
      case StudyMaterialType.challenge:
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(material.title),
            content: Text(material.subtitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      case StudyMaterialType.flashcard:
        final repository = flashcardRepository;
        if (repository == null) return;
        final linkedCard = (await repository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (linkedCard != null && linkedCard.id != card.id && context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FlashcardDetailsPage(
                card: linkedCard,
                flashcardRepository: flashcardRepository,
                questionRepository: questionRepository,
                materialRepository: materialRepository,
              ),
            ),
          );
        }
      case StudyMaterialType.document:
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(material.title),
            content: Text(material.subtitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      case StudyMaterialType.diagram:
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(material.title),
            content: Text(material.subtitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
    }
  }

  IconData _materialIcon(StudyMaterialType type) {
    return switch (type) {
      StudyMaterialType.flashcard => Icons.style_outlined,
      StudyMaterialType.question => Icons.quiz_outlined,
      StudyMaterialType.challenge => Icons.code_outlined,
      StudyMaterialType.document => Icons.description_outlined,
      StudyMaterialType.diagram => Icons.account_tree_outlined,
    };
  }
}
