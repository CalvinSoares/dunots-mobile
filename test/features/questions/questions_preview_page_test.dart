import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/questions/question_details_page.dart';
import 'package:dunots_mobile/features/questions/questions_preview_page.dart';

void main() {
  Question question() {
    return Question(
      id: 'question-widget',
      number: 7,
      statement: 'Qual protocolo resolve nomes?',
      alternatives: const ['DNS', 'HTTP', 'SSH', 'FTP', 'SMTP'],
      correctAlternativeIndex: 0,
      explanation: 'DNS associa nomes a endereços.',
      contest: 'Teste',
      role: 'Redes',
      createdAt: DateTime(2026, 9, 30),
    );
  }

  testWidgets('abre o cadastro e os detalhes da questão', (tester) async {
    final repository = InMemoryQuestionRepository(questions: [question()]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuestionsPreviewPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qual protocolo resolve nomes?'), findsOneWidget);

    await tester.tap(find.text('Nova questão'));
    await tester.pumpAndSettle();
    expect(find.text('Alternativas A–E'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'DNS');
    await tester.pumpAndSettle();
    expect(find.text('1 de 1 questões'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Qual protocolo resolve nomes?'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Qual protocolo resolve nomes?'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionDetailsPage), findsOneWidget);
    expect(find.text('DNS'), findsOneWidget);
  });
}
