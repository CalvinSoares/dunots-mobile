import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/questions/questions_preview_page.dart';
import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';
import 'package:dunots_mobile/features/quizzes/quiz_attempt_page.dart';

void main() {
  testWidgets('seleciona questões e inicia uma tentativa', (tester) async {
    final questionRepository = InMemoryQuestionRepository(
      questions: [
        Question(
          id: 'question-1',
          number: 1,
          statement: 'Qual protocolo resolve nomes?',
          alternatives: const ['DNS', 'HTTP', 'SSH', 'FTP', 'SMTP'],
          correctAlternativeIndex: 0,
          explanation: '',
          contest: 'Teste',
          role: 'Redes',
          createdAt: DateTime(2026, 9, 30),
        ),
      ],
    );
    final attemptRepository = InMemoryQuizAttemptRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionsPreviewPage(
            repository: questionRepository,
            attemptRepository: attemptRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(Checkbox),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Montar simulado (1)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Simulado de redes');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Questão 1 de 1'), findsOneWidget);
    expect(
      (await attemptRepository.getAll()).single.title,
      'Simulado de redes',
    );
  });

  testWidgets('edita a configuração antes de responder', (tester) async {
    final questionRepository = InMemoryQuestionRepository();
    final attempt = QuizAttempt(
      id: 'attempt-edit',
      title: 'Simulado original',
      questionIds: const ['question-001', 'question-002'],
      currentIndex: 1,
      status: QuizAttemptStatus.inProgress,
      answers: const {},
      createdAt: DateTime(2026, 9, 30),
      updatedAt: DateTime(2026, 9, 30),
    );
    final attemptRepository = InMemoryQuizAttemptRepository(
      attempts: [attempt],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizAttemptPage(
          attempt: attempt,
          questionRepository: questionRepository,
          attemptRepository: attemptRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar configuração do simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Editar simulado'), findsOneWidget);

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'Simulado revisado');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Qual topologia conecta'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 questão(ões) selecionada(s)'), findsOneWidget);
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();

    expect(find.text('Simulado revisado'), findsOneWidget);
    expect(find.text('Questão 1 de 1'), findsOneWidget);
    final updated = (await attemptRepository.getAll()).single;
    expect(updated.title, 'Simulado revisado');
    expect(updated.questionIds, ['question-001']);

    await tester.tap(find.byTooltip('Marcar para revisão'));
    await tester.pumpAndSettle();
    expect((await attemptRepository.getAll()).single.reviewQuestionIds, [
      'question-001',
    ]);
    await tester.tap(find.byType(RadioListTile<int>).first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Editar configuração do simulado'), findsNothing);
  });

  testWidgets('navega pela próxima questão pendente no progresso', (
    tester,
  ) async {
    final attempt = QuizAttempt(
      id: 'attempt-progress',
      title: 'Revisão de redes',
      questionIds: const ['question-001', 'question-002'],
      currentIndex: 0,
      status: QuizAttemptStatus.inProgress,
      answers: const {'question-001': 0},
      reviewQuestionIds: const ['question-002'],
      createdAt: DateTime(2026, 9, 30),
      updatedAt: DateTime(2026, 9, 30),
    );
    final attemptRepository = InMemoryQuizAttemptRepository(
      attempts: [attempt],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizAttemptPage(
          attempt: attempt,
          questionRepository: InMemoryQuestionRepository(),
          attemptRepository: attemptRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver progresso do simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Progresso do simulado'), findsOneWidget);
    expect(find.text('1/2 respondidas'), findsOneWidget);
    expect(find.text('Pendências por tópico'), findsOneWidget);
    expect(find.text('1 pendente(s) · 1 total'), findsOneWidget);
    await tester.tap(find.text('Topologias').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Topologias').last);
    await tester.pumpAndSettle();
    final progressDialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: progressDialog,
        matching: find.textContaining('Qual topologia conecta'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: progressDialog,
        matching: find.textContaining('Qual é a função principal'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Próxima pendente'));
    await tester.pumpAndSettle();

    expect(find.text('Questão 2 de 2'), findsOneWidget);
    expect((await attemptRepository.getAll()).single.currentIndex, 1);

    await tester.tap(find.byTooltip('Ver progresso do simulado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar marcadas'));
    await tester.pumpAndSettle();
    expect(find.text('Questão 2 de 2'), findsOneWidget);
  });

  testWidgets('revisa pendentes antes de finalizar o simulado', (tester) async {
    final attempt = QuizAttempt(
      id: 'attempt-final-review',
      title: 'Simulado para finalizar',
      questionIds: const ['question-001', 'question-002'],
      currentIndex: 1,
      status: QuizAttemptStatus.inProgress,
      answers: const {'question-001': 0},
      reviewQuestionIds: const ['question-002'],
      createdAt: DateTime(2026, 9, 30),
      updatedAt: DateTime(2026, 9, 30),
    );
    final attemptRepository = InMemoryQuizAttemptRepository(
      attempts: [attempt],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizAttemptPage(
          attempt: attempt,
          questionRepository: InMemoryQuestionRepository(),
          attemptRepository: attemptRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar antes de finalizar'), findsOneWidget);
    expect(find.textContaining('1 pendente(s)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('Qual topologia conecta'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Finalizar simulado'));
    await tester.pumpAndSettle();

    expect(find.text('Resultado do simulado'), findsOneWidget);
    expect(
      (await attemptRepository.getAll()).single.status,
      QuizAttemptStatus.finished,
    );
  });

  testWidgets('reabre simulado finalizado sem alterar respostas', (
    tester,
  ) async {
    final attempt = QuizAttempt(
      id: 'attempt-review-only',
      title: 'Simulado concluído',
      questionIds: const ['question-001', 'question-002'],
      currentIndex: 1,
      status: QuizAttemptStatus.finished,
      answers: const {'question-001': 0, 'question-002': 1},
      reviewQuestionIds: const ['question-001'],
      createdAt: DateTime(2026, 9, 30),
      updatedAt: DateTime(2026, 9, 30),
    );
    final attemptRepository = InMemoryQuizAttemptRepository(
      attempts: [attempt],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizAttemptPage(
          attempt: attempt,
          questionRepository: InMemoryQuestionRepository(),
          attemptRepository: attemptRepository,
          reviewOnly: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revisão · Simulado concluído'), findsOneWidget);
    expect(find.text('Modo revisão'), findsOneWidget);
    expect(find.text('Questão 2 de 2'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    final saved = (await attemptRepository.getAll()).single;
    expect(saved.status, QuizAttemptStatus.finished);
    expect(saved.currentIndex, 1);
    expect(saved.answers, attempt.answers);
    expect(saved.reviewQuestionIds, attempt.reviewQuestionIds);
    expect(saved.reviewNotes, isEmpty);
  });
}
