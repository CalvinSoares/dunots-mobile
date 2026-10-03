import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/domain/quiz_exam.dart';
import 'package:dunots_mobile/features/questions/question_form_dialog.dart';
import 'package:dunots_mobile/shared/widgets/dunots_modal.dart';

void main() {
  testWidgets('herda os metadados da prova selecionada', (tester) async {
    QuestionFormData? result;
    final exam = QuizExam(
      id: 'exam-1',
      title: 'Transpetro 2023',
      contestName: 'Transpetro',
      vacancy: 'Analista de Sistemas',
      proofVersion: 'Prova 6',
      createdAt: DateTime(2026, 10, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDunotsDrawer<QuestionFormData>(
                  context: context,
                  builder: (_) =>
                      QuestionFormDialog(exams: [exam], initialExamId: exam.id),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Cargo'), findsNothing);
    expect(find.text('Concurso'), findsNothing);
    expect(find.text('Prova/versão'), findsNothing);
    expect(find.text('Detalhes opcionais'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '42');
    await tester.enterText(
      fields.at(1),
      'Qual protocolo é orientado à conexão?',
    );
    for (var index = 2; index < 7; index++) {
      await tester.enterText(fields.at(index), 'Alternativa ${index - 1}');
    }
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.question.examId, 'exam-1');
    expect(result!.question.contest, 'Transpetro');
    expect(result!.question.role, 'Analista de Sistemas');
    expect(result!.question.exam, 'Transpetro 2023');
  });

  testWidgets('mantém a explicação do gabarito acima da navegação do sistema', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(bottom: 24),
            viewPadding: const EdgeInsets.only(bottom: 24),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDunotsDrawer<void>(
                context: context,
                builder: (_) => const QuestionFormDialog(),
              ),
              child: const Text('Abrir questão'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir questão'));
    await tester.pumpAndSettle();
    final dialogScrollable = find.descendant(
      of: find.byType(DunotsModal),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Detalhes opcionais'),
      220,
      scrollable: dialogScrollable.first,
    );
    await tester.tap(find.text('Detalhes opcionais'));
    await tester.pumpAndSettle();

    final explanationField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Explicação do gabarito',
    );
    await tester.ensureVisible(explanationField);
    await tester.pumpAndSettle();

    final fieldBounds = tester.getRect(explanationField);
    expect(fieldBounds.bottom, lessThanOrEqualTo(616));
    expect(tester.takeException(), isNull);
  });
}
