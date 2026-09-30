import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import '../questions/data/question_repository.dart';
import 'data/quiz_attempt_repository.dart';
import 'domain/quiz_attempt.dart';
import 'quiz_attempt_page.dart';
import 'quiz_result_page.dart';

class QuizHistoryPage extends StatefulWidget {
  final QuizAttemptRepository attemptRepository;
  final QuestionRepository questionRepository;

  const QuizHistoryPage({
    super.key,
    required this.attemptRepository,
    required this.questionRepository,
  });

  @override
  State<QuizHistoryPage> createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  late Future<List<QuizAttempt>> _attemptsFuture;
  String _search = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de simulados')),
      body: FutureBuilder<List<QuizAttempt>>(
        future: _attemptsFuture,
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
          final attempts = snapshot.data ?? const <QuizAttempt>[];
          if (attempts.isEmpty) {
            return const StudyEmptyState(
              title: 'Nenhum simulado criado ainda.',
              detail: 'Selecione questões para montar seu primeiro simulado.',
              icon: Icons.assignment_outlined,
            );
          }
          final filteredAttempts = attempts
              .where((attempt) {
                final matchesSearch =
                    _search.trim().isEmpty ||
                    attempt.title.toLowerCase().contains(
                      _search.trim().toLowerCase(),
                    );
                final matchesStatus =
                    _statusFilter == 'all' ||
                    (_statusFilter == 'finished' &&
                        attempt.status == QuizAttemptStatus.finished) ||
                    (_statusFilter == 'inProgress' &&
                        attempt.status == QuizAttemptStatus.inProgress);
                return matchesSearch && matchesStatus;
              })
              .toList(growable: false);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar simulados',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'inProgress',
                          child: Text('Em andamento'),
                        ),
                        DropdownMenuItem(
                          value: 'finished',
                          child: Text('Finalizados'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _statusFilter = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredAttempts.length} de ${attempts.length} simulados',
                    style: const TextStyle(color: Color(0xFFB6B7AD)),
                  ),
                ),
              ),
              if (filteredAttempts.isEmpty)
                const Expanded(
                  child: Center(
                    child: StudyEmptyState(
                      title: 'Nenhum simulado corresponde aos filtros.',
                      detail: 'Tente limpar a busca ou alterar o status.',
                      icon: Icons.filter_alt_off_outlined,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: filteredAttempts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final attempt = filteredAttempts[index];
                      final isFinished =
                          attempt.status == QuizAttemptStatus.finished;
                      return Card(
                        child: ListTile(
                          onTap: () => _openAttempt(attempt),
                          leading: Icon(
                            isFinished ? Icons.check_circle : Icons.play_circle,
                            color: isFinished
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                          ),
                          title: Text(
                            attempt.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${attempt.questionIds.length} questões · '
                            '${isFinished ? 'finalizado' : 'em andamento'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Excluir simulado',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(attempt),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    _attemptsFuture = widget.attemptRepository.getAll();
  }

  Future<void> _openAttempt(QuizAttempt attempt) async {
    final page = attempt.status == QuizAttemptStatus.finished
        ? QuizResultPage(
            attempt: attempt,
            questionRepository: widget.questionRepository,
            attemptRepository: widget.attemptRepository,
          )
        : QuizAttemptPage(
            attempt: attempt,
            questionRepository: widget.questionRepository,
            attemptRepository: widget.attemptRepository,
          );
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) {
      setState(_reload);
    }
  }

  Future<void> _confirmDelete(QuizAttempt attempt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir simulado?'),
        content: Text('A tentativa "${attempt.title}" será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.attemptRepository.delete(attempt.id);
      if (mounted) {
        setState(_reload);
      }
    }
  }
}
