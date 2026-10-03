# Dunots Mobile

Aplicativo Flutter do Dunots, mantido como repositório independente do desktop.
O mobile é Android-first, offline-first e usa SQLite local, com contrato de
sincronização compatível com desktop/web.

## Estado atual

- Release instalável atual: `0.1.0+1`.
- Navegação para Hoje, Estudar, Questões e Trilhas.
- Flashcards com SRS, sessões, histórico, progresso e metas.
- Trilhas com tópicos, subtópicos, materiais, documentos e progresso.
- Simulados, importação de questões e persistência local.
- Sincronização por pacote, backup, conflitos e rede local em evolução.

## Executar

```bash
flutter pub get
flutter run
```

## Validar

```bash
dart format lib test
flutter analyze
flutter test
```

## Gerar APK

```bash
flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/`. A assinatura atual é para
instalação pessoal; a assinatura de publicação será configurada antes da Play
Store.

## Documentação

Consulte [`docs/README.md`](docs/README.md) para o índice. O padrão visual está
em [`docs/design.md`](docs/design.md), e as regras de colaboração em
[`AGENTS.md`](AGENTS.md).
