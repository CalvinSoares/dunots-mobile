import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import '../../shared/widgets/dunots_modal.dart';
import '../../shared/widgets/study_widgets.dart';
import '../questions/data/question_repository.dart';
import '../questions/domain/question.dart';
import 'data/quiz_attempt_repository.dart';
import 'domain/quiz_attempt.dart';
import 'quiz_result_page.dart';

class QuizAttemptPage extends StatefulWidget {
  final QuizAttempt attempt;
  final QuestionRepository questionRepository;
  final QuizAttemptRepository attemptRepository;
  final bool reviewOnly;

  const QuizAttemptPage({
    super.key,
    required this.attempt,
    required this.questionRepository,
    required this.attemptRepository,
    this.reviewOnly = false,
  });

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  late QuizAttempt _attempt;
  late Future<List<Question>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _attempt = widget.attempt;
    _questionsFuture = widget.questionRepository.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isReadOnly ? 'Revisão · ${_attempt.title}' : _attempt.title,
        ),
        actions: [
          IconButton(
            tooltip: 'Ver progresso do simulado',
            onPressed: _openProgress,
            icon: const Icon(Icons.insights_outlined),
          ),
          if (_canEditConfiguration)
            IconButton(
              tooltip: 'Editar configuração do simulado',
              onPressed: _editConfiguration,
              icon: const Icon(Icons.tune),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: StudyLoadingState(message: 'Carregando questões...'),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Não foi possível carregar o simulado.'),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _questionsFuture = widget.questionRepository.getAll();
                        }),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final questionsById = {
              for (final question in snapshot.data ?? const <Question>[])
                question.id: question,
            };
            final questions = _attempt.questionIds
                .map((id) => questionsById[id])
                .whereType<Question>()
                .toList(growable: false);
            if (questions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Nenhuma questão deste simulado está disponível.',
                  ),
                ),
              );
            }

            final index = _attempt.currentIndex.clamp(0, questions.length - 1);
            final question = questions[index];
            return _buildQuestion(context, question, index, questions.length);
          },
        ),
      ),
    );
  }

  bool get _canEditConfiguration =>
      _attempt.status == QuizAttemptStatus.inProgress &&
      _attempt.answers.isEmpty;

  Future<void> _editConfiguration() async {
    final questions = await _questionsFuture;
    if (!mounted || !_canEditConfiguration) {
      return;
    }

    final data = await showDunotsDrawer<_QuizAttemptEditData>(
      context: context,
      builder: (_) =>
          _QuizAttemptEditDialog(attempt: _attempt, questions: questions),
    );
    if (data == null || !mounted) {
      return;
    }

    final updated = _attempt.copyWith(
      title: data.title,
      questionIds: List.unmodifiable(data.questionIds),
      currentIndex: data.questionIds.isEmpty
          ? 0
          : _attempt.currentIndex.clamp(0, data.questionIds.length - 1),
      answers: {
        for (final entry in _attempt.answers.entries)
          if (data.questionIds.contains(entry.key)) entry.key: entry.value,
      },
      reviewQuestionIds: _attempt.reviewQuestionIds
          .where(data.questionIds.contains)
          .toList(growable: false),
      updatedAt: DateTime.now(),
    );
    await widget.attemptRepository.update(updated);
    if (mounted) {
      setState(() => _attempt = updated);
    }
  }

  Future<void> _openProgress() async {
    final allQuestions = await _questionsFuture;
    if (!mounted) {
      return;
    }

    final questionsById = {
      for (final question in allQuestions) question.id: question,
    };
    final questions = _attempt.questionIds
        .map((id) => questionsById[id])
        .whereType<Question>()
        .toList(growable: false);
    if (questions.isEmpty) {
      return;
    }

    final targetIndex = await showDunotsDrawer<int>(
      context: context,
      builder: (_) =>
          _QuizProgressDialog(attempt: _attempt, questions: questions),
    );
    if (targetIndex != null && mounted) {
      await _moveTo(targetIndex);
    }
  }

  Widget _buildQuestion(
    BuildContext context,
    Question question,
    int index,
    int total,
  ) {
    final selected = _attempt.answers[question.id];
    final isFinished = _attempt.status == QuizAttemptStatus.finished;
    final isReadOnly = _isReadOnly;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questão ${index + 1} de $total',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isReadOnly && _isMarkedForReview(question.id))
              const Icon(Icons.flag, color: DunotsColors.purple)
            else if (!isFinished)
              IconButton(
                tooltip: _isMarkedForReview(question.id)
                    ? 'Remover marcação de revisão'
                    : 'Marcar para revisão',
                onPressed: () => _toggleReview(question.id),
                icon: Icon(
                  _isMarkedForReview(question.id)
                      ? Icons.flag
                      : Icons.flag_outlined,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (isReadOnly)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Modo revisão'),
              subtitle: Text(
                'Respostas e pontuação não podem ser alteradas nesta tela.',
              ),
            ),
          ),
        if (isReadOnly) const SizedBox(height: 16),
        Text(
          question.statement,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        RadioGroup<int>(
          groupValue: selected,
          onChanged: (value) {
            if (isFinished || isReadOnly) {
              return;
            }
            if (value != null) {
              _saveAnswer(question.id, value);
            }
          },
          child: Column(
            children: question.alternatives.asMap().entries.map((entry) {
              return Card(
                child: RadioListTile<int>(
                  value: entry.key,
                  title: Text(entry.value),
                  secondary: Text(String.fromCharCode(65 + entry.key)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (isReadOnly) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: const Text('Anotação de revisão'),
              subtitle: Text(
                _attempt.reviewNotes[question.id]?.trim().isNotEmpty == true
                    ? _attempt.reviewNotes[question.id]!
                    : 'Nenhuma anotação registrada.',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            if (index > 0)
              OutlinedButton.icon(
                onPressed: () => _moveTo(index - 1),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Anterior'),
              ),
            const Spacer(),
            if (index < total - 1)
              FilledButton.icon(
                onPressed: () => _moveTo(index + 1),
                icon: const Icon(Icons.chevron_right),
                label: const Text('Próxima'),
              )
            else if (!isFinished)
              FilledButton.icon(
                onPressed: () => _finish(total),
                icon: const Icon(Icons.check),
                label: const Text('Finalizar'),
              ),
          ],
        ),
      ],
    );
  }

  bool get _isReadOnly =>
      widget.reviewOnly || _attempt.status == QuizAttemptStatus.finished;

  Future<void> _saveAnswer(String questionId, int answer) async {
    final answers = Map<String, int?>.from(_attempt.answers)
      ..[questionId] = answer;
    final updated = _attempt.copyWith(
      answers: answers,
      updatedAt: DateTime.now(),
    );
    await widget.attemptRepository.update(updated);
    if (mounted) {
      setState(() => _attempt = updated);
    }
  }

  bool _isMarkedForReview(String questionId) {
    return _attempt.reviewQuestionIds.contains(questionId);
  }

  Future<void> _toggleReview(String questionId) async {
    final reviewQuestionIds = _attempt.reviewQuestionIds.toSet();
    if (!reviewQuestionIds.add(questionId)) {
      reviewQuestionIds.remove(questionId);
    }
    final updated = _attempt.copyWith(
      reviewQuestionIds: _attempt.questionIds
          .where(reviewQuestionIds.contains)
          .toList(growable: false),
      updatedAt: DateTime.now(),
    );
    await widget.attemptRepository.update(updated);
    if (mounted) {
      setState(() => _attempt = updated);
    }
  }

  Future<void> _moveTo(int index) async {
    final updated = _attempt.copyWith(
      currentIndex: index,
      updatedAt: DateTime.now(),
    );
    if (widget.reviewOnly) {
      if (mounted) {
        setState(() => _attempt = updated);
      }
      return;
    }
    await widget.attemptRepository.update(updated);
    if (mounted) {
      setState(() => _attempt = updated);
    }
  }

  Future<void> _finish(int total) async {
    final allQuestions = await _questionsFuture;
    if (!mounted) {
      return;
    }
    final questionsById = {
      for (final question in allQuestions) question.id: question,
    };
    final questions = _attempt.questionIds
        .map((id) => questionsById[id])
        .whereType<Question>()
        .toList(growable: false);
    final decision = await showDunotsDrawer<_FinalReviewDecision>(
      context: context,
      builder: (_) =>
          _FinalReviewDialog(attempt: _attempt, questions: questions),
    );
    if (decision == null || !mounted) {
      return;
    }
    if (decision.questionIndex != null) {
      await _moveTo(decision.questionIndex!);
      return;
    }
    if (!decision.finalize) {
      return;
    }
    final updated = _attempt.copyWith(
      status: QuizAttemptStatus.finished,
      updatedAt: DateTime.now(),
    );
    await widget.attemptRepository.update(updated);
    if (mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            attempt: updated,
            questionRepository: widget.questionRepository,
            attemptRepository: widget.attemptRepository,
          ),
        ),
      );
    }
  }
}

class _FinalReviewDecision {
  final bool finalize;
  final int? questionIndex;

  const _FinalReviewDecision._({required this.finalize, this.questionIndex});

  const _FinalReviewDecision.finish() : this._(finalize: true);

  const _FinalReviewDecision.goTo(int index)
    : this._(finalize: false, questionIndex: index);
}

class _FinalReviewDialog extends StatelessWidget {
  final QuizAttempt attempt;
  final List<Question> questions;

  const _FinalReviewDialog({required this.attempt, required this.questions});

  @override
  Widget build(BuildContext context) {
    final pending = questions
        .asMap()
        .entries
        .where((entry) => !attempt.answers.containsKey(entry.value.id))
        .toList(growable: false);
    final markedAnswered = questions
        .asMap()
        .entries
        .where(
          (entry) =>
              attempt.answers.containsKey(entry.value.id) &&
              attempt.reviewQuestionIds.contains(entry.value.id),
        )
        .toList(growable: false);
    final markedCount = questions
        .where((question) => attempt.reviewQuestionIds.contains(question.id))
        .length;
    final items = <Widget>[
      Text(
        '${attempt.answers.length}/${questions.length} respondidas · '
        '${pending.length} pendente(s) · $markedCount marcada(s)',
      ),
      const SizedBox(height: 14),
    ];

    void addSection(String title, List<MapEntry<int, Question>> entries) {
      if (entries.isEmpty) {
        return;
      }
      items.add(
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
      items.add(const SizedBox(height: 6));
      for (final entry in entries) {
        final question = entry.value;
        items.add(
          Card(
            child: ListTile(
              onTap: () =>
                  Navigator.of(context)
                      .pop(_FinalReviewDecision.goTo(entry.key)),
              leading: CircleAvatar(child: Text('${entry.key + 1}')),
              title: Text(
                question.statement,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  if (question.topic.isNotEmpty) question.topic,
                  if (attempt.reviewQuestionIds.contains(question.id))
                    'Marcada para revisão',
                ].join(' · '),
              ),
              trailing: Icon(
                attempt.reviewQuestionIds.contains(question.id)
                    ? Icons.flag
                    : Icons.help_outline,
                color: attempt.reviewQuestionIds.contains(question.id)
                    ? DunotsColors.purple
                    : DunotsColors.amber,
              ),
            ),
          ),
        );
      }
    }

    addSection('Questões pendentes', pending);
    addSection('Marcadas já respondidas', markedAnswered);
    if (pending.isEmpty && markedAnswered.isEmpty) {
      items.add(const Text('Todas as questões foram respondidas e revisadas.'));
    }
    final dialogHeight = (MediaQuery.sizeOf(context).height * 0.48)
        .clamp(220.0, 480.0)
        .toDouble();

    return DunotsModal(
      title: 'Revisar antes de finalizar',
      subtitle: 'Confira pendências e marcações antes de concluir.',
      icon: Icons.fact_check_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: dialogHeight,
        child: ListView(children: items),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Continuar respondendo'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(const _FinalReviewDecision.finish()),
          icon: const Icon(Icons.check),
          label: const Text('Finalizar simulado'),
        ),
      ],
    );
  }
}

class _QuizProgressDialog extends StatefulWidget {
  final QuizAttempt attempt;
  final List<Question> questions;

  const _QuizProgressDialog({required this.attempt, required this.questions});

  @override
  State<_QuizProgressDialog> createState() => _QuizProgressDialogState();
}

class _QuizProgressDialogState extends State<_QuizProgressDialog> {
  String topicFilter = '';
  String statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final answeredCount = widget.questions
        .where((question) => widget.attempt.answers.containsKey(question.id))
        .length;
    final progress = widget.questions.isEmpty
        ? 0.0
        : answeredCount / widget.questions.length;
    final topicProgress = <String, _TopicProgress>{};
    for (final question in widget.questions) {
      final topic = question.topic.trim().isEmpty
          ? 'Sem tópico'
          : question.topic.trim();
      final current = topicProgress[topic] ?? const _TopicProgress();
      topicProgress[topic] = current.copyWith(
        total: current.total + 1,
        answered:
            current.answered +
            (widget.attempt.answers.containsKey(question.id) ? 1 : 0),
      );
    }
    final orderedTopicProgress = topicProgress.entries.toList()
      ..sort((a, b) {
        final pendingComparison = b.value.pending.compareTo(a.value.pending);
        return pendingComparison == 0
            ? a.key.compareTo(b.key)
            : pendingComparison;
      });
    final topics =
        widget.questions
            .map((question) => question.topic.trim())
            .where((topic) => topic.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final visibleEntries = widget.questions
        .asMap()
        .entries
        .where((entry) {
          final question = entry.value;
          final matchesTopic =
              topicFilter.isEmpty || question.topic.trim() == topicFilter;
          final answered = widget.attempt.answers.containsKey(question.id);
          final matchesStatus =
              statusFilter == 'all' ||
              (statusFilter == 'pending' && !answered) ||
              (statusFilter == 'answered' && answered) ||
              (statusFilter == 'marked' &&
                  widget.attempt.reviewQuestionIds.contains(question.id));
          return matchesTopic && matchesStatus;
        })
        .toList(growable: false);
    final pendingIndex = visibleEntries
        .where((entry) => !widget.attempt.answers.containsKey(entry.value.id))
        .map((entry) => entry.key)
        .firstOrNull;
    final markedIndex = visibleEntries
        .where(
          (entry) => widget.attempt.reviewQuestionIds.contains(entry.value.id),
        )
        .map((entry) => entry.key)
        .firstOrNull;
    final compact = MediaQuery.sizeOf(context).width < 520;
    final topicDropdown = DropdownButtonFormField<String>(
      initialValue: topicFilter,
      decoration: const InputDecoration(labelText: 'Tópico'),
      items: [
        const DropdownMenuItem(value: '', child: Text('Todos')),
        ...topics.map(
          (topic) => DropdownMenuItem(
            value: topic,
            child: Text(topic, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => topicFilter = value);
        }
      },
    );
    final statusDropdown = DropdownButtonFormField<String>(
      initialValue: statusFilter,
      decoration: const InputDecoration(labelText: 'Status'),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Todas')),
        DropdownMenuItem(value: 'pending', child: Text('Pendentes')),
        DropdownMenuItem(value: 'answered', child: Text('Respondidas')),
        DropdownMenuItem(value: 'marked', child: Text('Marcadas')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => statusFilter = value);
        }
      },
    );
    final dialogHeight = (MediaQuery.sizeOf(context).height * 0.46)
        .clamp(240.0, 480.0)
        .toDouble();

    return DunotsModal(
      title: 'Progresso do simulado',
      subtitle: 'Filtre por tópico ou status e escolha onde continuar.',
      icon: Icons.insights_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$answeredCount/${widget.questions.length} respondidas'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            const Text(
              'Pendências por tópico',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: orderedTopicProgress.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final entry = orderedTopicProgress[index];
                  final topic = entry.key;
                  final topicData = entry.value;
                  return SizedBox(
                    width: 190,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => setState(() => topicFilter = topic),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${topicData.pending} pendente(s) · ${topicData.total} total',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: topicData.ratio),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (compact) ...[
              topicDropdown,
              const SizedBox(height: 10),
              statusDropdown,
            ] else
              Row(
                children: [
                  Expanded(child: topicDropdown),
                  const SizedBox(width: 10),
                  Expanded(child: statusDropdown),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              '${visibleEntries.length} questão(ões) exibida(s)',
              style: const TextStyle(color: Color(0xFFB6B7AD)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visibleEntries.isEmpty
                  ? const Center(child: Text('Nenhuma questão neste filtro.'))
                  : ListView.separated(
                      itemCount: visibleEntries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final entry = visibleEntries[index];
                        final question = entry.value;
                        final answered = widget.attempt.answers.containsKey(
                          question.id,
                        );
                        final isCurrent =
                            entry.key == widget.attempt.currentIndex;
                        return Card(
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            onTap: () => Navigator.of(context).pop(entry.key),
                            leading: CircleAvatar(
                              child: Text('${entry.key + 1}'),
                            ),
                            title: Text(
                              question.statement,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                widget.attempt.reviewQuestionIds.contains(
                                      question.id,
                                    )
                                    ? 'Marcada para revisão'
                                    : answered
                                    ? 'Respondida'
                                    : 'Pendente',
                                if (question.topic.isNotEmpty) question.topic,
                              ].join(' · '),
                            ),
                            trailing: Icon(
                              widget.attempt.reviewQuestionIds.contains(
                                    question.id,
                                  )
                                  ? Icons.flag
                                  : answered
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color:
                                  widget.attempt.reviewQuestionIds.contains(
                                    question.id,
                                  )
                                  ? DunotsColors.purple
                                  : answered
                                  ? DunotsColors.mint
                                  : DunotsColors.amber,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: pendingIndex == null
              ? null
              : () => Navigator.of(context).pop(pendingIndex),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Próxima pendente'),
        ),
        OutlinedButton.icon(
          onPressed: markedIndex == null
              ? null
              : () => Navigator.of(context).pop(markedIndex),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Revisar marcadas'),
        ),
      ],
    );
  }
}

class _TopicProgress {
  final int total;
  final int answered;

  const _TopicProgress({this.total = 0, this.answered = 0});

  int get pending => total - answered;

  double get ratio => total == 0 ? 0 : answered / total;

  _TopicProgress copyWith({int? total, int? answered}) {
    return _TopicProgress(
      total: total ?? this.total,
      answered: answered ?? this.answered,
    );
  }
}

class _QuizAttemptEditData {
  final String title;
  final List<String> questionIds;

  const _QuizAttemptEditData({required this.title, required this.questionIds});
}

class _QuizAttemptEditDialog extends StatefulWidget {
  final QuizAttempt attempt;
  final List<Question> questions;

  const _QuizAttemptEditDialog({
    required this.attempt,
    required this.questions,
  });

  @override
  State<_QuizAttemptEditDialog> createState() => _QuizAttemptEditDialogState();
}

class _QuizAttemptEditDialogState extends State<_QuizAttemptEditDialog> {
  late final TextEditingController titleController;
  late final Set<String> selectedIds;
  String query = '';
  String? validationError;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.attempt.title);
    selectedIds = widget.attempt.questionIds.toSet();
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final visibleQuestions = widget.questions.where((question) {
      final searchable = [
        question.number?.toString() ?? '',
        question.statement,
        question.topic,
        question.exam,
      ].join(' ').toLowerCase();
      return normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
    }).toList();

    return DunotsModal(
      title: 'Editar simulado',
      subtitle: 'Ajuste o nome e as questões desta tentativa.',
      icon: Icons.tune,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * 0.56,
        child: Column(
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nome do simulado *',
                errorText: validationError,
              ),
              onChanged: (_) {
                if (validationError != null) {
                  setState(() => validationError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${selectedIds.length} questão(ões) selecionada(s)',
                style: const TextStyle(color: Color(0xFFB6B7AD)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar questões',
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visibleQuestions.isEmpty
                  ? const Center(child: Text('Nenhuma questão encontrada.'))
                  : ListView.builder(
                      itemCount: visibleQuestions.length,
                      itemBuilder: (context, index) {
                        final question = visibleQuestions[index];
                        return CheckboxListTile(
                          value: selectedIds.contains(question.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedIds.add(question.id);
                              } else {
                                selectedIds.remove(question.id);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            '#${question.number ?? index + 1} · ${question.statement}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: question.topic.isEmpty
                              ? null
                              : Text(question.topic),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar alterações'),
        ),
      ],
    );
  }

  void _submit() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      setState(() => validationError = 'Informe um nome.');
      return;
    }
    if (selectedIds.isEmpty) {
      setState(() => validationError = 'Selecione pelo menos uma questão.');
      return;
    }

    final questionOrder = widget.attempt.questionIds
        .where(selectedIds.contains)
        .toList(growable: false);
    Navigator.of(context)
        .pop(_QuizAttemptEditData(title: title, questionIds: questionOrder));
  }
}
