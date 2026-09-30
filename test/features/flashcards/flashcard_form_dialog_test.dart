import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/flashcards/flashcard_form_dialog.dart';

void main() {
  testWidgets('cria flashcard com código e tags', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                final card = await showDialog(
                  context: context,
                  builder: (_) => const FlashcardFormDialog(),
                );
                if (context.mounted && card != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(card.front)));
                }
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'O que é uma VLAN?');
    await tester.enterText(fields.at(1), 'Uma rede local virtual.');
    await tester.enterText(fields.at(2), 'interface vlan 10');
    await tester.enterText(fields.at(3), 'redes, switching');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('O que é uma VLAN?'), findsOneWidget);
  });
}
