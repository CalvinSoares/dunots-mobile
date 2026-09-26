# Dunots Mobile — checklist de cada fase

## Aprendizado

- [ ] Consigo explicar o objetivo da fase.
- [ ] Sei quais conceitos de Dart/Flutter foram usados.
- [ ] Fiz o exercício guiado.
- [ ] Sei explicar cada arquivo alterado.
- [ ] Registrei decisões relevantes.

## Implementação

- [ ] A mudança tem escopo pequeno.
- [ ] UI não mistura regras de negócio com persistência.
- [ ] Loading, vazio e erro foram considerados.
- [ ] Entradas foram validadas.
- [ ] Operações longas dão feedback.
- [ ] Dados privados não aparecem em logs.

## Validação pelo usuário

Executar dentro de mobile:

    flutter pub get
    dart format lib test
    flutter analyze
    flutter test

Nos marcos de aplicativo instalável:

    flutter build apk --debug

Manual:

- [ ] Fluxo feliz.
- [ ] Entrada vazia ou inválida.
- [ ] Fechar e reabrir.
- [ ] Confirmar persistência.
- [ ] Testar tela pequena e fonte ampliada quando necessário.

## Git pelo usuário

O assistente não executa Git. Revisar e executar comandos granulares:

    git status
    git diff -- path/do/arquivo.dart
    git add path/do/arquivo.dart test/arquivo_test.dart
    git commit -m "feat(mobile): descreve a mudança"
    git push

Não usar git add . sem revisar. Partes independentes devem ter commits separados.

## Fechamento

- [ ] Checklist de aprendizado completo.
- [ ] flutter analyze passou.
- [ ] flutter test passou.
- [ ] Teste manual realizado.
- [ ] Documentação atualizada.
- [ ] Diff revisado.
- [ ] Commits criados pelo usuário.
- [ ] Push feito para o repositório correto.