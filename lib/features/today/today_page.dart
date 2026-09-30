import 'package:flutter/material.dart';

import '../../core/models/flashcard.dart';
import '../flashcards/data/flashcard_repository.dart';
import '../questions/data/question_repository.dart';
import '../quizzes/data/quiz_attempt_repository.dart';
import '../quizzes/domain/quiz_attempt.dart';
import '../quizzes/quiz_attempt_page.dart';
import '../roadmaps/data/study_track_repository.dart';
import '../roadmaps/domain/study_track.dart';
import '../../shared/widgets/study_widgets.dart';

class TodayPage extends StatefulWidget {
  final FlashcardRepository? flashcardRepository;
  final StudyTrackRepository? trackRepository;
  final QuestionRepository? questionRepository;
  final QuizAttemptRepository? attemptRepository;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenQuestions;

  const TodayPage({
    super.key,
    this.flashcardRepository,
    this.trackRepository,
    this.questionRepository,
    this.attemptRepository,
    this.onOpenFlashcards,
    this.onOpenQuestions,
  });

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late Future<_TodayData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_TodayData> _loadData() async {
    final cards =
        await (widget.flashcardRepository ?? InMemoryFlashcardRepository())
            .getAll();
    final tracks =
        await (widget.trackRepository ?? InMemoryStudyTrackRepository())
            .getAll();
    final attempts =
        await (widget.attemptRepository ?? InMemoryQuizAttemptRepository())
            .getAll();
    final inProgress = attempts
        .where((attempt) => attempt.status == QuizAttemptStatus.inProgress)
        .toList(growable: false);
    return _TodayData(cards: cards, tracks: tracks, inProgress: inProgress);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TodayData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const StudyLoadingState(message: 'Carregando seu mural...');
        }
        if (snapshot.hasError) {
          return StudyErrorState(
            message: 'Não foi possível carregar o mural.',
            onRetry: () => setState(() => _dataFuture = _loadData()),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const StudyEmptyState(
            title: 'Nenhum dado disponível.',
            detail: 'Tente novamente para atualizar seu mural.',
            icon: Icons.dashboard_outlined,
          );
        }
        return _buildContent(context, data);
      },
    );
  }

  Widget _buildContent(BuildContext context, _TodayData data) {
    final firstAttempt = data.inProgress.firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DunotsBrand(),
                  const SizedBox(height: 28),
                  Text(
                    'seu caderno de estudos',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: const Color(0xFFB6B7AD)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vamos avançar um pouco hoje?',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 22),
                  ReviewCard(
                    count: data.cards.length,
                    onPressed: widget.onOpenFlashcards,
                  ),
                  const SizedBox(height: 18),
                  if (isWide)
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: 'flashcards',
                            value: '${data.cards.length}',
                            icon: Icons.style_outlined,
                            color: const Color(0xFF78B8FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'trilhas ativas',
                            value: '${data.tracks.length}',
                            icon: Icons.route_outlined,
                            color: const Color(0xFFB79BFF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: 'simulados em andamento',
                            value: '${data.inProgress.length}',
                            icon: Icons.assignment_outlined,
                            color: const Color(0xFFFFC857),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MetricCard(
                                label: 'flashcards',
                                value: '${data.cards.length}',
                                icon: Icons.style_outlined,
                                color: const Color(0xFF78B8FF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricCard(
                                label: 'trilhas ativas',
                                value: '${data.tracks.length}',
                                icon: Icons.route_outlined,
                                color: const Color(0xFFB79BFF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MetricCard(
                          label: 'simulados em andamento',
                          value: '${data.inProgress.length}',
                          icon: Icons.assignment_outlined,
                          color: const Color(0xFFFFC857),
                        ),
                      ],
                    ),
                  const SizedBox(height: 26),
                  Text(
                    'acesso rápido',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  QuickAction(
                    icon: Icons.style_outlined,
                    title: 'Abrir flashcards',
                    subtitle: '${data.cards.length} cartões cadastrados',
                    color: const Color(0xFFFF7168),
                    onTap: widget.onOpenFlashcards,
                  ),
                  const SizedBox(height: 10),
                  QuickAction(
                    icon: Icons.assignment_outlined,
                    title: firstAttempt == null
                        ? 'Montar simulado'
                        : 'Continuar simulado',
                    subtitle: firstAttempt == null
                        ? 'Escolha questões para começar'
                        : firstAttempt.title,
                    color: const Color(0xFFFFC857),
                    onTap: firstAttempt == null
                        ? widget.onOpenQuestions
                        : () => _openAttempt(firstAttempt),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'trilhas em andamento',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (data.tracks.isEmpty)
                    const ExampleListTile(
                      title: 'Nenhuma trilha criada',
                      detail: 'Crie uma trilha para organizar seus estudos.',
                    )
                  else
                    ...data.tracks
                        .take(3)
                        .map(
                          (track) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ProgressListTile(track: track),
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAttempt(QuizAttempt attempt) async {
    final questionRepository = widget.questionRepository;
    final attemptRepository = widget.attemptRepository;
    if (questionRepository == null || attemptRepository == null || !mounted) {
      widget.onOpenQuestions?.call();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAttemptPage(
          attempt: attempt,
          questionRepository: questionRepository,
          attemptRepository: attemptRepository,
        ),
      ),
    );
    if (mounted) {
      setState(() => _dataFuture = _loadData());
    }
  }
}

class _TodayData {
  final List<Flashcard> cards;
  final List<StudyTrack> tracks;
  final List<QuizAttempt> inProgress;

  const _TodayData({
    required this.cards,
    required this.tracks,
    required this.inProgress,
  });
}
