import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/shared/widgets/study_widgets.dart';

void main() {
  testWidgets('mantém hierarquia compacta para cabeçalho e ações', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const StudyScreenHeader(
                  icon: Icons.style_outlined,
                  title: 'Um título de estudo suficientemente longo para testar reticências',
                  subtitle: 'Uma descrição que deve permanecer secundária.',
                ),
                StudyPrimaryAction(
                  icon: Icons.play_arrow,
                  label: 'Estudar agora',
                  expanded: true,
                  onPressed: () {},
                ),
                StudySearchField(
                  query: 'rede',
                  onChanged: (_) {},
                  onClear: () {},
                ),
                StudyFilterButton(active: true, onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Estudar agora'), findsOneWidget);
    expect(find.byTooltip('Limpar busca'), findsOneWidget);
    expect(find.byTooltip('Filtrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
