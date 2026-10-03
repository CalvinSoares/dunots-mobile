import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/shared/widgets/dunots_modal.dart';

void main() {
  testWidgets('padroniza confirmação destrutiva e retorna decisão', (
    tester,
  ) async {
    bool? decision;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              decision = await showDunotsDrawer<bool>(
                context: context,
                builder: (_) => const DunotsConfirmDialog(
                  title: 'Excluir item?',
                  message: 'O item será removido.',
                  confirmLabel: 'Excluir',
                ),
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('O item será removido.'), findsOneWidget);
    expect(find.text('Excluir'), findsOneWidget);
    expect(find.byTooltip('Fechar painel'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(decision, isTrue);
  });

  testWidgets('fecha o drawer ao arrastar a alça para baixo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDunotsDrawer<void>(
              context: context,
              builder: (_) => DunotsModal(
                title: 'Editar flashcard',
                actions: const [],
                child: const Text('Conteúdo do painel'),
              ),
            ),
            child: const Text('Abrir drawer arrastável'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir drawer arrastável'));
    await tester.pumpAndSettle();
    expect(find.text('Editar flashcard'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('dunots-drawer-handle')),
      const Offset(0, 360),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar flashcard'), findsNothing);
  });

  testWidgets('mantém o título visível quando o teclado reduz o modal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            viewInsets: EdgeInsets.only(bottom: 390),
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDunotsDrawer<void>(
                context: context,
                builder: (_) => DunotsModal(
                  title: 'Editar tópico',
                  icon: Icons.folder_outlined,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Salvar'),
                    ),
                  ],
                  child: const Column(
                    children: [
                      TextField(autofocus: true),
                      SizedBox(height: 18),
                      TextField(maxLines: 4),
                    ],
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Editar tópico'), findsOneWidget);
    expect(find.byTooltip('Fechar painel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite alcançar o último campo com o teclado aberto', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            viewInsets: EdgeInsets.only(bottom: 390),
          ),
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDunotsDrawer<void>(
                context: context,
                builder: (_) => DunotsModal(
                  title: 'Nova prova/vaga',
                  icon: Icons.folder_outlined,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Salvar'),
                    ),
                  ],
                  child: Column(
                    children: [
                      for (var index = 0; index < 8; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: index == 7
                                  ? 'Gabarito'
                                  : 'Campo $index',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final lastField = find.byType(TextField).last;
    await tester.ensureVisible(lastField);
    await tester.pumpAndSettle();
    await tester.enterText(lastField, 'gabarito.pdf');

    expect(find.text('Gabarito'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('não ultrapassa a largura útil em 320 dp', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDunotsDrawer<void>(
              context: context,
              builder: (_) => DunotsModal(
                title: 'Nova questão',
                subtitle: 'Organize enunciado, alternativas e gabarito.',
                icon: Icons.quiz_outlined,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Criar'),
                  ),
                ],
                child: const TextField(
                  decoration: InputDecoration(labelText: 'Enunciado'),
                  maxLines: 4,
                ),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final drawerBounds = tester.getRect(find.byType(DunotsModal));
    expect(drawerBounds.left, 0);
    expect(drawerBounds.right, 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ancora a folha na base em larguras compactas', (tester) async {
    for (final viewport in const [
      Size(320, 800),
      Size(360, 800),
      Size(390, 800),
      Size(414, 800),
      Size(840, 800),
      Size(800, 360),
    ]) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 24),
              viewPadding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDunotsDrawer<void>(
                context: context,
                builder: (_) => DunotsModal(
                  title: 'Editar flashcard',
                  icon: Icons.style_outlined,
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Salvar'),
                    ),
                  ],
                  child: const TextField(
                    decoration: InputDecoration(labelText: 'Frente'),
                  ),
                ),
              ),
              child: const Text('Abrir drawer'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir drawer'));
      await tester.pumpAndSettle();

      final drawerBounds = tester.getRect(find.byType(DunotsModal));
      expect(drawerBounds.left, 0);
      expect(drawerBounds.right, viewport.width);
      expect(
        tester.getRect(find.byTooltip('Fechar painel')).bottom,
        lessThanOrEqualTo(viewport.height - 24),
      );

      await tester.tap(find.byTooltip('Fechar painel'));
      await tester.pumpAndSettle();
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
