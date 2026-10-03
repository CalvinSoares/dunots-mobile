import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/questions/question_details_page.dart';
import 'package:dunots_mobile/features/questions/question_bulk_form_dialog.dart';
import 'package:dunots_mobile/features/questions/pdf_question_import_dialog.dart';
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
    expect(find.text('Cargo'), findsNothing);
    expect(find.text('Concurso'), findsNothing);
    expect(find.text('Prova/versão'), findsNothing);
    expect(find.text('Detalhes opcionais'), findsOneWidget);
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

  testWidgets('mantém a explicação acima da navegação do sistema', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final longExplanation =
        'A explicação fica disponível por inteiro acima da navegação do sistema.';
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: QuestionDetailsPage(
            question: Question(
              id: 'question-safe-area',
              number: 12,
              statement: 'Qual alternativa descreve uma área segura?',
              alternatives: const ['A', 'B', 'C', 'D', 'E'],
              correctAlternativeIndex: 0,
              explanation: longExplanation,
              contest: '',
              role: '',
              createdAt: DateTime(2026, 10, 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final explanationCard = find.byKey(
      const ValueKey('question-explanation-card'),
    );
    await tester.scrollUntilVisible(
      explanationCard,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(explanationCard, findsOneWidget);
    await tester.ensureVisible(explanationCard);
    await tester.pumpAndSettle();
    final explanationBounds = tester.getRect(explanationCard);

    expect(
      find.byKey(const ValueKey('question-details-safe-area')),
      findsOneWidget,
    );
    expect(explanationBounds.bottom, lessThanOrEqualTo(616));
    expect(tester.takeException(), isNull);
  });

  testWidgets('organiza ações e filtros em fluxos secundários', (tester) async {
    final repository = InMemoryQuestionRepository(questions: [question()]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuestionsPreviewPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova questão'), findsOneWidget);
    expect(find.byTooltip('Mais ações das questões'), findsOneWidget);
    expect(find.text('Cadastro em massa'), findsNothing);

    await tester.tap(find.byTooltip('Mais ações das questões'));
    await tester.pumpAndSettle();
    expect(find.text('Atualizar questões'), findsOneWidget);
    expect(find.text('Cadastro em massa'), findsOneWidget);
    expect(find.text('Importar PDF'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtrar questões'));
    await tester.pumpAndSettle();
    expect(find.text('Concurso'), findsOneWidget);
    expect(find.text('Prova/vaga'), findsOneWidget);
  });

  testWidgets('mantém busca e ações principais utilizáveis em tela compacta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 800,
            child: QuestionsPreviewPage(
              repository: InMemoryQuestionRepository(questions: [question()]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nova questão'), findsOneWidget);
    expect(find.byTooltip('Mais ações das questões'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Filtrar questões'), findsOneWidget);
    expect(find.text('Concurso'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapta o importador de PDF para tela compacta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 800,
            child: PdfQuestionImportDialog(exams: const []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Importar prova e gabarito'), findsOneWidget);
    expect(find.text('PDF da prova *'), findsOneWidget);
    expect(find.text('Disciplina/assunto *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empilha os campos do cadastro em massa no mobile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: Scaffold(body: QuestionBulkFormDialog(exams: const [])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cadastro rápido em massa'), findsOneWidget);
    expect(find.text('Disciplina/assunto *'), findsOneWidget);
    expect(find.text('Tópico'), findsOneWidget);
    expect(find.text('Questões *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
