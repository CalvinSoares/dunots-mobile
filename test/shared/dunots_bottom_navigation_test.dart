import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/app/dunots_theme.dart';
import 'package:dunots_mobile/shared/widgets/dunots_bottom_navigation.dart';

void main() {
  testWidgets('mantém quatro destinos rotulados e reporta a seleção', (
    tester,
  ) async {
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildDunotsTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: DunotsBottomNavigation(
              selectedIndex: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Estudar'), findsOneWidget);
    expect(find.text('Questões'), findsOneWidget);
    expect(find.text('Trilhas'), findsOneWidget);

    await tester.tap(find.text('Questões'));
    await tester.pump(const Duration(milliseconds: 380));

    expect(selected, 2);
    expect(find.byIcon(Icons.quiz), findsOneWidget);
  });

  testWidgets('centraliza o ícone ativo no círculo em cada destino', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDunotsTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: DunotsBottomNavigation(
              selectedIndex: selected,
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    expect(tester.getCenter(find.byIcon(Icons.today)).dx, closeTo(45, 0.5));

    await tester.tap(find.text('Questões'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));

    expect(selected, 2);
    expect(tester.getCenter(find.byIcon(Icons.quiz)).dx, closeTo(225, 0.5));
    expect(tester.takeException(), isNull);
  });
}
