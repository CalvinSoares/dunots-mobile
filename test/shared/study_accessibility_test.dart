import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/shared/widgets/study_widgets.dart';

void main() {
  testWidgets('anuncia filtros ativos e cabeçalho da tela', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const StudyScreenHeader(
                icon: Icons.quiz_outlined,
                title: 'Questões',
                subtitle: 'Cadastre e revise.',
              ),
              StudyFilterButton(active: true, onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(StudyScreenHeader)).label,
      contains('Questões. Cadastre e revise.'),
    );
    expect(
      tester.getSemantics(find.byType(StudyFilterButton)).label,
      contains('Filtrar. Filtros ativos'),
    );
    expect(tester.takeException(), isNull);
  });
}
