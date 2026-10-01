import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';
import 'package:dunots_mobile/features/quizzes/quiz_history_page.dart';

void main() {
  testWidgets('abre o resultado pelo histórico', (tester) async {
    final now = DateTime(2026, 9, 30);
    final questionRepository = InMemoryQuestionRepository(
      questions: [
        Question(
          id: 'q-history',
          number: 4,
          statement: 'Qual protocolo resolve nomes?',
          alternatives: const ['DNS', 'HTTP', 'SSH', 'FTP', 'SMTP'],
          correctAlternativeIndex: 0,
          explanation: '',
          contest: 'Teste',
          role: 'Redes',
          createdAt: now,
        ),
      ],
    );
    final attemptRepository = InMemoryQuizAttemptRepository(
      attempts: [
        QuizAttempt(
          id: 'quiz-history',
          title: 'Simulado finalizado',
          questionIds: const ['q-history'],
          currentIndex: 0,
          status: QuizAttemptStatus.finished,
          answers: const {'q-history': 0},
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizHistoryPage(
          attemptRepository: attemptRepository,
          questionRepository: questionRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'não existe');
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum simulado corresponde aos filtros.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulado finalizado'));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsWidgets);
    expect(find.text('Acertos'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Reabrir revisão'), 300);
    expect(find.text('Reabrir revisão'), findsOneWidget);

    await tester.tap(find.text('Reabrir revisão'));
    await tester.pumpAndSettle();
    expect(find.text('Modo revisão'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum simulado criado ainda.'), findsOneWidget);
  });

  testWidgets('resume erradas, pendentes e marcadas no resultado', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 30);
    final questionRepository = InMemoryQuestionRepository(
      questions: [
        Question(
          id: 'q-wrong',
          number: 12,
          statement: 'Qual protocolo foi respondido incorretamente?',
          alternatives: const ['DNS', 'HTTP', 'SSH', 'FTP', 'SMTP'],
          correctAlternativeIndex: 0,
          explanation: '',
          contest: 'Teste',
          role: 'Redes',
          createdAt: now,
        ),
        Question(
          id: 'q-pending',
          number: 13,
          statement: 'Qual questão ficou pendente?',
          alternatives: const ['A', 'B', 'C', 'D', 'E'],
          correctAlternativeIndex: 1,
          explanation: '',
          contest: 'Teste',
          role: 'Redes',
          createdAt: now,
        ),
        Question(
          id: 'q-marked',
          number: 14,
          statement: 'Qual questão foi marcada para revisão?',
          alternatives: const ['A', 'B', 'C', 'D', 'E'],
          correctAlternativeIndex: 0,
          explanation: '',
          contest: 'Teste',
          role: 'Redes',
          createdAt: now,
        ),
      ],
    );
    final attemptRepository = InMemoryQuizAttemptRepository(
      attempts: [
        QuizAttempt(
          id: 'quiz-review-summary',
          title: 'Simulado com revisão',
          questionIds: const ['q-wrong', 'q-pending', 'q-marked'],
          currentIndex: 2,
          status: QuizAttemptStatus.finished,
          answers: const {'q-wrong': 1, 'q-marked': 0},
          reviewQuestionIds: const ['q-marked'],
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizHistoryPage(
          attemptRepository: attemptRepository,
          questionRepository: questionRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulado com revisão'));
    await tester.pumpAndSettle();

    expect(find.text('Resumo da revisão'), findsOneWidget);
    expect(find.text('Questões erradas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Questões pendentes'), 300);
    expect(find.text('Questões pendentes'), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.widgetWithText(ListTile, 'Questões erradas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Qual protocolo foi respondido incorretamente?'),
      findsWidgets,
    );
    expect(find.text('Sua resposta: B · Gabarito: A'), findsWidgets);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Questões marcadas'), 300);
    await tester.tap(find.widgetWithText(ListTile, 'Questões marcadas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Marcada para revisão'), findsOneWidget);
  });
}
