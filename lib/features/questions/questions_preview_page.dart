import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import '../../shared/widgets/dunots_modal.dart';
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
import '../quizzes/quiz_pdf_export_service.dart';

class QuestionsPreviewPage extends StatefulWidget {
  final bool showHeader;
  final QuestionRepository? repository;
  final QuizAttemptRepository? attemptRepository;
  final QuizExamRepository? examRepository;

  const QuestionsPreviewPage({
    super.key,
    this.showHeader = true,
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
  List<QuizExam> _exams = const [];
  String _search = '';
  String? _selectedContest;
  String? _selectedRole;
  String? _selectedExamId;
  String? _selectedBoard;
  int? _selectedYear;
  String? _selectedVersion;
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
      showHeader: widget.showHeader,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FilledButton.icon(
                onPressed: _createQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Nova questão'),
              ),
              StudyContextMenu<String>(
                tooltip: 'Mais ações das questões',
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      setState(_reload);
                    case 'bulk':
                      _createQuestionsInBulk();
                    case 'pdf':
                      _importPdf();
                    case 'exams':
                      _openExams();
                    case 'history':
                      _openHistory();
                    case 'selection':
                      _toggleSelectionMode();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.refresh),
                      title: Text('Atualizar questões'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bulk',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.playlist_add),
                      title: Text('Cadastro em massa'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.picture_as_pdf_outlined),
                      title: Text('Importar PDF'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'exams',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.folder_outlined),
                      title: Text('Provas e vagas'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history),
                      title: Text('Histórico'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'selection',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _selectionMode ? Icons.close : Icons.checklist_outlined,
                      ),
                      title: Text(
                        _selectionMode
                            ? 'Sair da seleção'
                            : 'Selecionar questões',
                      ),
                    ),
                  ),
                ],
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
              final examIds = _exams
                  .where(
                    (exam) =>
                        questions.any((question) => question.examId == exam.id),
                  )
                  .map((exam) => exam.id)
                  .toList(growable: false);
              final boards = _optionsForExams(_exams, (exam) => exam.board);
              final years =
                  _exams
                      .map((exam) => exam.year)
                      .whereType<int>()
                      .toSet()
                      .toList()
                    ..sort((a, b) => b.compareTo(a));
              final versions = _optionsForExams(
                _exams,
                (exam) => exam.proofVersion,
              );
              final activeContest = contests.contains(_selectedContest)
                  ? _selectedContest
                  : null;
              final activeRole = roles.contains(_selectedRole)
                  ? _selectedRole
                  : null;
              final activeExamId = examIds.contains(_selectedExamId)
                  ? _selectedExamId
                  : null;
              final activeBoard = boards.contains(_selectedBoard)
                  ? _selectedBoard
                  : null;
              final activeYear = years.contains(_selectedYear)
                  ? _selectedYear
                  : null;
              final activeVersion = versions.contains(_selectedVersion)
                  ? _selectedVersion
                  : null;
              final activeFilterCount = [
                activeContest,
                activeRole,
                activeExamId,
                activeBoard,
                activeYear,
                activeVersion,
              ].where((value) => value != null).length;
              final visibleQuestions = QuestionFilters(
                search: _search,
                contest: activeContest,
                role: activeRole,
                examId: activeExamId,
                board: activeBoard,
                year: activeYear,
                proofVersion: activeVersion,
              ).apply(questions, exams: _exams);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StudySearchField(
                          hintText: 'Buscar questões',
                          query: _search,
                          onChanged: (value) => setState(() => _search = value),
                          onClear: () => setState(() => _search = ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StudyFilterButton(
                        active: activeFilterCount > 0,
                        tooltip: 'Filtrar questões',
                        onPressed: () => _showQuestionFilters(
                          contests: contests,
                          roles: roles,
                          exams: _exams,
                          examIds: examIds,
                          boards: boards,
                          years: years,
                          versions: versions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectionMode
                              ? '${_selectedQuestionIds.length} selecionada(s) · ${visibleQuestions.length} visíveis'
                              : '${visibleQuestions.length} de ${questions.length} questões',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DunotsColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (visibleQuestions.isNotEmpty)
                        IconButton.filledTonal(
                          tooltip: 'Exportar prova em PDF',
                          onPressed: () => _exportExam(visibleQuestions),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                        ),
                    ],
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

  Future<void> _showQuestionFilters({
    required List<String> contests,
    required List<String> roles,
    required List<QuizExam> exams,
    required List<String> examIds,
    required List<String> boards,
    required List<int> years,
    required List<String> versions,
  }) async {
    var contest = _selectedContest;
    var role = _selectedRole;
    var examId = _selectedExamId;
    var board = _selectedBoard;
    var year = _selectedYear;
    var version = _selectedVersion;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          void update(VoidCallback localUpdate, VoidCallback pageUpdate) {
            setSheetState(localUpdate);
            setState(pageUpdate);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext).colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filtrar questões',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: contest,
                    decoration: const InputDecoration(labelText: 'Concurso'),
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
                    onChanged: (value) => update(
                      () => contest = value,
                      () => _selectedContest = value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: role,
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
                        update(() => role = value, () => _selectedRole = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: examId,
                    decoration: const InputDecoration(labelText: 'Prova/vaga'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...exams
                          .where((exam) => examIds.contains(exam.id))
                          .map(
                            (exam) => DropdownMenuItem<String?>(
                              value: exam.id,
                              child: Text(
                                '${exam.title} · ${exam.vacancy}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                    ],
                    onChanged: (value) => update(
                      () => examId = value,
                      () => _selectedExamId = value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: board,
                    decoration: const InputDecoration(labelText: 'Banca'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...boards.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) => update(
                      () => board = value,
                      () => _selectedBoard = value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...years.map(
                        (value) => DropdownMenuItem<int?>(
                          value: value,
                          child: Text('$value'),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        update(() => year = value, () => _selectedYear = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: version,
                    decoration: const InputDecoration(labelText: 'Versão'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...versions.map(
                        (value) => DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                      ),
                    ],
                    onChanged: (value) => update(
                      () => version = value,
                      () => _selectedVersion = value,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setSheetState(() {
                              contest = null;
                              role = null;
                              examId = null;
                              board = null;
                              year = null;
                              version = null;
                            });
                            _clearFilters();
                          },
                          child: const Text('Limpar filtros'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Concluir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _reload() {
    _questionsFuture = _repository.getAll();
    _examsFuture = _examRepository.getAll();
    _examsFuture.then((exams) {
      if (mounted) setState(() => _exams = exams);
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedQuestionIds.clear();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedContest = null;
      _selectedRole = null;
      _selectedExamId = null;
      _selectedBoard = null;
      _selectedYear = null;
      _selectedVersion = null;
    });
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

  List<String> _optionsForExams(
    Iterable<QuizExam> exams,
    String? Function(QuizExam) valueOf,
  ) {
    return exams
        .map(valueOf)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _createQuestion({QuizExam? initialExam}) async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDunotsDrawer<QuestionFormData>(
      context: context,
      builder: (_) =>
          QuestionFormDialog(exams: exams, initialExamId: initialExam?.id),
    );
    if (data == null || !mounted) {
      return;
    }
    await _save(() => _repository.create(data.question));
  }

  Future<void> _createQuestionsInBulk() async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDunotsDrawer<QuestionBulkFormData>(
      context: context,
      builder: (_) => QuestionBulkFormDialog(exams: exams),
    );
    if (data == null || !mounted) return;
    await _save(() => _repository.createMany(data.questions));
  }

  Future<void> _importPdf() async {
    final exams = await _examsFuture;
    if (!mounted) return;
    final data = await showDunotsDrawer<PdfQuestionImportData>(
      context: context,
      builder: (_) => PdfQuestionImportDialog(exams: exams),
    );
    if (data == null || !mounted) return;
    await _save(() => _repository.createMany(data.questions));
  }

  Future<void> _createQuiz() async {
    final data = await showDunotsDrawer<QuizFormData>(
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

  Future<void> _exportExam(Iterable<Question> questions) async {
    try {
      const service = QuizPdfExportService();
      final bytes = await service.exportExam(
        title: 'Dunots — Prova exportada',
        questions: questions,
        includeAnswerKey: true,
        includeExplanations: true,
        includeNotes: true,
      );
      final uri = await service.savePdf(
        bytes,
        fileName: 'dunots-prova-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              uri == null
                  ? 'Exportação cancelada.'
                  : 'Prova exportada para ${uri.toString()}',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível exportar a prova: $error')),
        );
      }
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
    final data = await showDunotsDrawer<QuestionFormData>(
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
    await showDunotsDrawer<void>(
      context: context,
      builder: (_) => QuizExamListDialog(
        repository: _examRepository,
        onCreateQuestion: (exam) async {
          if (mounted) Navigator.of(context).pop();
          await _createQuestion(initialExam: exam);
        },
      ),
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
    final confirmed = await showDunotsDrawer<bool>(
      context: context,
      builder: (_) => const DunotsConfirmDialog(
        title: 'Excluir questão?',
        message: 'Esta questão será removida do dispositivo.',
        confirmLabel: 'Excluir',
      ),
    );
    if (confirmed == true && mounted) {
      await _save(() => _repository.delete(question.id));
    }
  }
}
