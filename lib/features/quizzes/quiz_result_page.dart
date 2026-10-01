import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import '../questions/data/question_repository.dart';
import '../questions/domain/question.dart';
import 'data/quiz_attempt_repository.dart';
import 'domain/quiz_attempt.dart';
import 'domain/quiz_attempt_result.dart';
import 'quiz_attempt_page.dart';
import 'quiz_pdf_export_service.dart';

class QuizResultPage extends StatefulWidget {
  final QuizAttempt attempt;
  final QuestionRepository questionRepository;
  final QuizAttemptRepository attemptRepository;

  const QuizResultPage({
    super.key,
    required this.attempt,
    required this.questionRepository,
    required this.attemptRepository,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  late Future<List<Question>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado do simulado')),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: StudyLoadingState(message: 'Calculando resultado...'),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: StudyErrorState(
                message: 'Não foi possível calcular o resultado.',
                onRetry: () => setState(_reload),
              ),
            );
          }
          final questions = snapshot.data ?? const <Question>[];
          final result = QuizAttemptResult.fromAttempt(
            widget.attempt,
            questions,
          );
          final topicResults = QuizAttemptResult.byTopic(
            widget.attempt,
            questions,
          );
          final examResults = QuizAttemptResult.byExam(
            widget.attempt,
            questions,
          );
          final questionsById = {
            for (final question in questions) question.id: question,
          };
          final attemptQuestions = widget.attempt.questionIds
              .map((questionId) => questionsById[questionId])
              .whereType<Question>()
              .toList(growable: false);
          if (attemptQuestions.isEmpty) {
            return const Center(
              child: StudyEmptyState(
                title: 'Nenhuma questão disponível para este resultado.',
                detail: 'As questões podem ter sido removidas ou ainda não sincronizadas.',
                icon: Icons.quiz_outlined,
              ),
            );
          }
          final incorrectQuestions = attemptQuestions
              .where((question) {
                final answer = widget.attempt.answers[question.id];
                return answer != null &&
                    answer != question.correctAlternativeIndex;
              })
              .toList(growable: false);
          final unansweredQuestions = attemptQuestions
              .where((question) => widget.attempt.answers[question.id] == null)
              .toList(growable: false);
          final markedQuestions = attemptQuestions
              .where(
                (question) =>
                    widget.attempt.reviewQuestionIds.contains(question.id),
              )
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.attempt.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _exportResult(attemptQuestions),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar resultado em PDF'),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '${result.percentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text('aproveitamento'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ResultRow(
                label: 'Acertos',
                value: result.correct,
                color: Colors.green,
              ),
              _ResultRow(
                label: 'Erros',
                value: result.incorrect,
                color: Colors.red,
              ),
              _ResultRow(
                label: 'Não respondidas',
                value: result.unanswered,
                color: Colors.orange,
              ),
              const SizedBox(height: 22),
              Text(
                'Resumo da revisão',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              _ReviewSummaryCard(
                label: 'Questões erradas',
                count: incorrectQuestions.length,
                icon: Icons.cancel,
                color: Colors.red,
                onTap: incorrectQuestions.isEmpty
                    ? null
                    : () => _showReviewDialog(
                        'Questões erradas',
                        incorrectQuestions,
                      ),
              ),
              _ReviewSummaryCard(
                label: 'Questões pendentes',
                count: unansweredQuestions.length,
                icon: Icons.help_outline,
                color: Colors.orange,
                onTap: unansweredQuestions.isEmpty
                    ? null
                    : () => _showReviewDialog(
                        'Questões pendentes',
                        unansweredQuestions,
                      ),
              ),
              _ReviewSummaryCard(
                label: 'Questões marcadas',
                count: markedQuestions.length,
                icon: Icons.flag,
                color: Colors.deepPurple,
                onTap: markedQuestions.isEmpty
                    ? null
                    : () => _showReviewDialog(
                        'Questões marcadas',
                        markedQuestions,
                      ),
              ),
              if (topicResults.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'Desempenho por tópico',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...topicResults.entries.map((entry) {
                  final topicResult = entry.value;
                  return _TopicResultCard(
                    topic: entry.key,
                    result: topicResult,
                  );
                }),
              ],
              if (examResults.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'Desempenho por concurso/prova',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...examResults.entries.map((entry) {
                  return _TopicResultCard(
                    topic: entry.key,
                    result: entry.value,
                  );
                }),
              ],
              const SizedBox(height: 22),
              Text(
                'Revisão das respostas',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...widget.attempt.questionIds.map((questionId) {
                final question = questionsById[questionId];
                if (question == null) {
                  return const SizedBox.shrink();
                }
                return _QuestionReviewCard(
                  question: question,
                  selectedAnswer: widget.attempt.answers[question.id],
                );
              }),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _openReview,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Reabrir revisão'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar ao histórico'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    _questionsFuture = widget.questionRepository.getAll();
  }

  Future<void> _exportResult(Iterable<Question> questions) async {
    try {
      const service = QuizPdfExportService();
      final bytes = await service.exportResult(
        attempt: widget.attempt,
        questions: questions,
      );
      final uri = await service.savePdf(
        bytes,
        fileName:
            'dunots-resultado-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uri == null
                  ? 'Exportação cancelada.'
                  : 'Resultado exportado para ${uri.toString()}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível exportar o resultado: $error'),
          ),
        );
      }
    }
  }

  Future<void> _showReviewDialog(String title, List<Question> questions) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ReviewQuestionsDialog(
        title: title,
        questions: questions,
        attempt: widget.attempt,
      ),
    );
  }

  Future<void> _openReview() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAttemptPage(
          attempt: widget.attempt,
          questionRepository: widget.questionRepository,
          attemptRepository: widget.attemptRepository,
          reviewOnly: true,
        ),
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ReviewSummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        enabled: onTap != null,
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: Text(
          onTap == null ? 'Nenhuma questão nesta categoria' : 'Abrir revisão',
        ),
        trailing: Text(
          '$count',
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ReviewQuestionsDialog extends StatelessWidget {
  final String title;
  final List<Question> questions;
  final QuizAttempt attempt;

  const _ReviewQuestionsDialog({
    required this.title,
    required this.questions,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        height: 420,
        child: ListView.separated(
          itemCount: questions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final question = questions[index];
            final selectedAnswer = attempt.answers[question.id];
            final isMarked = attempt.reviewQuestionIds.contains(question.id);
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${question.number ?? index + 1}'),
                ),
                title: Text(
                  question.statement,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Sua resposta: ${_answerLabel(selectedAnswer)} · '
                  'Gabarito: ${_answerLabel(question.correctAlternativeIndex)}'
                  '${isMarked ? ' · Marcada para revisão' : ''}',
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  String _answerLabel(int? index) {
    return index == null ? 'não respondida' : String.fromCharCode(65 + index);
  }
}

class _TopicResultCard extends StatelessWidget {
  final String topic;
  final QuizAttemptResult result;

  const _TopicResultCard({required this.topic, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(topic),
        subtitle: Text('${result.correct}/${result.total} acertos'),
        trailing: Text(
          '${result.percentage.toStringAsFixed(0)}%',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final Question question;
  final int? selectedAnswer;

  const _QuestionReviewCard({required this.question, this.selectedAnswer});

  @override
  Widget build(BuildContext context) {
    final isUnanswered = selectedAnswer == null;
    final isCorrect = selectedAnswer == question.correctAlternativeIndex;
    final color = isUnanswered
        ? Colors.orange
        : isCorrect
        ? Colors.green
        : Colors.red;
    return Card(
      child: ListTile(
        leading: Icon(
          isUnanswered
              ? Icons.help_outline
              : isCorrect
              ? Icons.check_circle
              : Icons.cancel,
          color: color,
        ),
        title: Text(
          question.statement,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Sua resposta: ${_answerLabel(selectedAnswer)} · '
          'Gabarito: ${_answerLabel(question.correctAlternativeIndex)}',
        ),
      ),
    );
  }

  String _answerLabel(int? index) {
    return index == null ? 'não respondida' : String.fromCharCode(65 + index);
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, size: 14, color: color),
        title: Text(label),
        trailing: Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
