import 'dart:convert';

import 'package:flutter/material.dart';

import 'domain/question.dart';

class QuestionDetailsPage extends StatelessWidget {
  final Question question;

  const QuestionDetailsPage({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          question.number == null
              ? 'Detalhes da questão'
              : 'Questão ${question.number}',
        ),
      ),
      // A explicação costuma ser o último conteúdo da questão. A área segura
      // evita que ela termine atrás da navegação gestual ou dos botões do SO.
      body: SafeArea(
        key: const ValueKey('question-details-safe-area'),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (question.contest.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.business_outlined, size: 17),
                    label: Text(question.contest),
                  ),
                if (question.role.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.work_outline, size: 17),
                    label: Text(question.role),
                  ),
                if (question.topic.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.topic_outlined, size: 17),
                    label: Text(question.topic),
                  ),
                if (question.exam.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.description_outlined, size: 17),
                    label: Text(question.exam),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Enunciado',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              question.statement,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como estudada'),
            ),
            if (question.visualImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Imagem da fonte',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...question.visualImages.map(_buildVisualImage),
            ],
            const SizedBox(height: 24),
            Text(
              'Alternativas',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ...question.alternatives.asMap().entries.map((entry) {
              final isCorrect = entry.key == question.correctAlternativeIndex;
              return Card(
                color: isCorrect
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(String.fromCharCode(65 + entry.key)),
                  ),
                  title: Text(entry.value),
                  trailing: isCorrect
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
              );
            }),
            if (question.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Explicação do gabarito',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                key: const ValueKey('question-explanation-card'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(question.explanation),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVisualImage(String source) {
    final separator = source.indexOf(',');
    if (!source.startsWith('data:image/') || separator < 0) {
      return const SizedBox.shrink();
    }
    try {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(source.substring(separator + 1)),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      );
    } on FormatException {
      return const SizedBox.shrink();
    }
  }
}
