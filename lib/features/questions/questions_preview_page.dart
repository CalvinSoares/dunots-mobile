import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import '../quizzes/data/quiz_attempt_repository.dart';
import '../quizzes/domain/quiz_attempt.dart';
import '../quizzes/quiz_attempt_page.dart';
import '../quizzes/quiz_form_dialog.dart';
import '../quizzes/quiz_history_page.dart';
import 'data/question_repository.dart';
import 'data/quiz_exam_repository.dart';
import 'domain/question.dart';
import 'domain/quiz_exam.dart';
import 'question_form_dialog.dart';
import 'quiz_exam_list_dialog.dart';
import 'question_filters.dart';
import 'question_list_item.dart';
import 'question_bulk_form_dialog.dart';
import 'pdf_question_import_dialog.dart';

class QuestionsPreviewPage extends StatefulWidget {
  final QuestionRepository? repository;
  final QuizAttemptRepository? attemptRepository;
  final QuizExamRepository? examRepository;

  const QuestionsPreviewPage({
    super.key,
    this.repository,
    this.attemptRepository,
    this.examRepository,
  });

  @override
  State<QuestionsPreviewPage> createState() => _QuestionsPreviewPageState();
}

class _QuestionsPreviewPageState extends State<QuestionsPreviewPage> {
  late final QuestionRepository _repository;
  late final QuizAttemptRepository _attemptRepository;
  late final QuizExamRepository _examRepository;
  late Future<List<Question>> _questionsFuture;
  late Future<List<QuizExam>> _examsFuture;
  String _search = '';
  String? _selectedContest;
  String? _selectedRole;
  bool _selectionMode = false;
  final Set<String> _selectedQuestionIds = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryQuestionRepository();
    _attemptRepository =
        widget.attemptRepository ?? InMemoryQuizAttemptRepository();
    _examRepository = widget.examRepository ?? InMemoryQuizExamRepository();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.quiz_outlined,
      title: 'Questões',
      subtitle: 'Cadastre, revise e organize suas questões.',
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _createQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Nova questão'),
              ),
              OutlinedButton.icon(
                onPressed: _createQuestionsInBulk,
                icon: const Icon(Icons.playlist_add),
                label: const Text('Cadastro em massa'),
              ),
              OutlinedButton.icon(
                onPressed: _importPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Importar PDF'),
              ),
              OutlinedButton.icon(
                onPressed: _openExams,
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Provas/vagas'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectionMode = !_selectionMode;
                    if (!_selectionMode) {
                      _selectedQuestionIds.clear();
                    }
                  });
                },
                icon: Icon(
                  _selectionMode ? Icons.close : Icons.checklist_outlined,
                ),
                label: Text(_selectionMode ? 'Cancelar' : 'Selecionar'),
              ),
              OutlinedButton.icon(
                onPressed: _openHistory,
                icon: const Icon(Icons.history),
                label: const Text('Histórico'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Question>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const StudyLoadingState(
                  message: 'Carregando questões...',
                );
              }
              if (snapshot.hasError) {
                return StudyErrorState(
                  message: 'Não foi possível carregar as questões.',
                  onRetry: () => setState(_reload),
                );
              }
              final questions = snapshot.data ?? const <Question>[];
              if (questions.isEmpty) {
                return const StudyEmptyState(
                  title: 'Nenhuma questão cadastrada ainda.',
                  detail:
                      'Cadastre uma questão para montar seu primeiro simulado.',
                  icon: Icons.quiz_outlined,
                );
              }
              final contests = _optionsFor(
                questions,
                (question) => question.contest,
              );
              final roles = _optionsFor(questions, (question) => question.role);
              final activeContest = contests.contains(_selectedContest)
                  ? _selectedContest
                  : null;
              final activeRole = roles.contains(_selectedRole)
                  ? _selectedRole
                  : null;
              final visibleQuestions = QuestionFilters(
                search: _search,
                contest: activeContest,
                role: activeRole,
              ).apply(questions);
              return Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar questões',
                      hintText: 'Número, enunciado, cargo ou concurso',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: activeContest,
                          decoration: const InputDecoration(
                            labelText: 'Concurso',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...contests.map(
                              (value) => DropdownMenuItem<String?>(
                                value: value,
                                child: Text(value),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedContest = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: activeRole,
                          decoration: const InputDecoration(labelText: 'Cargo'),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ...roles.map(
                              (value) => DropdownMenuItem<String?>(
                                value: value,
                                child: Text(value),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedRole = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${visibleQuestions.length} de ${questions.length} questões',
                      style: const TextStyle(color: Color(0xFFB6B7AD)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_selectionMode && _selectedQuestionIds.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _createQuiz,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          'Montar simulado (${_selectedQuestionIds.length})',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (visibleQuestions.isEmpty)
                    const StudyEmptyState(
                      title: 'Nenhuma questão corresponde aos filtros.',
                      detail: 'Tente limpar a busca ou alterar os filtros.',
                      icon: Icons.filter_alt_off_outlined,
                    )
                  else
                    ...visibleQuestions.map((question) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QuestionListItem(
                          question: question,
                          onEdit: () => _editQuestion(question),
                          onDelete: () => _confirmDelete(question),
                          selectable: _selectionMode,
                          selected: _selectedQuestionIds.contains(question.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedQuestionIds.add(question.id);
                              } else {
                                _selectedQuestionIds.remove(question.id);
                              }
                            });
                          },
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _reload() {
    _questionsFuture = _repository.getAll();
    _examsFuture = _examRepository.getAll();
  }

  List<String> _optionsFor(
    Iterable<Question> questions,
    String Function(Question) valueOf,
  ) {
    return questions
        .map(valueOf)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _createQuestion() async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDialog<QuestionFormData>(
      context: context,
      builder: (_) => QuestionFormDialog(exams: exams),
    );
    if (data == null || !mounted) {
      return;
    }
    await _save(() => _repository.create(data.question));
  }

  Future<void> _createQuestionsInBulk() async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDialog<QuestionBulkFormData>(
      context: context,
      builder: (_) => QuestionBulkFormDialog(exams: exams),
    );
    if (data == null || !mounted) return;
    await _save(() => _repository.createMany(data.questions));
  }

  Future<void> _importPdf() async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDialog<PdfQuestionImportData>(
      context: context,
      builder: (_) => PdfQuestionImportDialog(exams: exams),
    );
    if (data == null || !mounted) return;
    await _save(() => _repository.createMany(data.questions));
  }

  Future<void> _createQuiz() async {
    final data = await showDialog<QuizFormData>(
      context: context,
      builder: (_) => const QuizFormDialog(),
    );
    if (data == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    final attempt = QuizAttempt(
      id: 'quiz-${now.microsecondsSinceEpoch}',
      title: data.title,
      questionIds: List.unmodifiable(_selectedQuestionIds),
      currentIndex: 0,
      status: QuizAttemptStatus.inProgress,
      answers: const {},
      createdAt: now,
      updatedAt: now,
    );
    await _attemptRepository.create(attempt);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAttemptPage(
          attempt: attempt,
          questionRepository: _repository,
          attemptRepository: _attemptRepository,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _selectionMode = false;
        _selectedQuestionIds.clear();
      });
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizHistoryPage(
          attemptRepository: _attemptRepository,
          questionRepository: _repository,
        ),
      ),
    );
  }

  Future<void> _editQuestion(Question question) async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDialog<QuestionFormData>(
      context: context,
      builder: (_) =>
          QuestionFormDialog(initialQuestion: question, exams: exams),
    );
    if (data == null || !mounted) {
      return;
    }
    await _save(() => _repository.update(data.question));
  }

  Future<void> _openExams() async {
    await showDialog<void>(
      context: context,
      builder: (_) => QuizExamListDialog(repository: _examRepository),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _save(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) {
        setState(_reload);
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }

  Future<void> _confirmDelete(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir questão?'),
        content: const Text('Esta questão será removida do dispositivo.'),
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
    if (confirmed == true && mounted) {
      await _save(() => _repository.delete(question.id));
    }
  }
}
