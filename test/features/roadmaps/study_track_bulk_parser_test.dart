import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/study_track_bulk_parser.dart';

void main() {
  test('reconhece tópicos, filhos e descrições no formato do desktop', () {
    final items = parseStudyTrackImportText('''
- Redes de computadores | Fundamentos
  - Modelo OSI | Sete camadas
  - TCP/IP | Pilha de protocolos
- Segurança | Controles e boas práticas
''');

    expect(items, hasLength(4));
    expect(items[0].title, 'Redes de computadores');
    expect(items[0].depth, 0);
    expect(items[1].title, 'Modelo OSI');
    expect(items[1].depth, 2);
    expect(items[1].description, 'Sete camadas');
    expect(items[2].depth, 2);
    expect(items[3].depth, 0);
  });

  test('preserva código e ignora fórmulas isoladas de uma colagem', () {
    final items = parseStudyTrackImportText('''
Topologias | Conceitos
```
N(N-1)/2
```
Malha | Enlaces e redundância
''');

    expect(items, hasLength(2));
    expect(items.first.description, contains('N(N-1)/2'));
    expect(items.last.title, 'Malha');
  });
}
