import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_node_details_page.dart';

void main() {
  testWidgets('copia o título do tópico ao tocá-lo', (tester) async {
    const title = 'Modelo OSI e protocolos de rede';
    final clipboardCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      clipboardCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: StudyNodeDetailsPage(
          node: StudyNode(
            id: 'topic-osi',
            trackId: 'track-networks',
            parentId: null,
            title: title,
            description: 'Camadas e protocolos de rede.',
            sortOrder: 0,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('copy-topic-title')));
    await tester.pump();

    final copyCalls = clipboardCalls
        .where((call) => call.method == 'Clipboard.setData')
        .toList();
    expect(copyCalls, hasLength(1));
    expect(copyCalls.single.arguments, <String, String>{'text': title});
    expect(find.text('Título copiado.'), findsOneWidget);
    expect(find.byTooltip('Copiar título'), findsOneWidget);
  });
}
