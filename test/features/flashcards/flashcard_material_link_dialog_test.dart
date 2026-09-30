import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/flashcards/flashcard_material_link_dialog.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';

void main() {
  testWidgets('busca e seleciona um material para vincular', (tester) async {
    List<String>? selectedIds;
    const materials = [
      StudyMaterial(
        id: 'question-1',
        type: StudyMaterialType.question,
        title: 'Questão sobre SQL',
        subtitle: 'Questão · Banco de Dados',
      ),
      StudyMaterial(
        id: 'document-1',
        type: StudyMaterialType.document,
        title: 'Resumo de redes',
        subtitle: 'Material de estudo',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                selectedIds = await showDialog<List<String>>(
                  context: context,
                  builder: (_) =>
                      const FlashcardMaterialLinkDialog(materials: materials),
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
    await tester.enterText(find.byType(TextField), 'SQL');
    await tester.pump();

    expect(find.text('Questão sobre SQL'), findsOneWidget);
    expect(find.text('Resumo de redes'), findsNothing);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('Vincular'));
    await tester.pumpAndSettle();

    expect(selectedIds, ['question-1']);
  });
}
