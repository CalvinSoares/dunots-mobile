# Dunots Mobile — plano de aprendizado e entrega

## 1. Propósito

Construir a versão mobile do Dunots em Flutter, aprendendo Dart, Flutter, arquitetura, persistência local, sincronização e publicação Android durante o processo.

O mobile deve ser útil mesmo sem internet e deve reutilizar o modelo conceitual do Dunots: questões, provas, simulados, flashcards, trilhas, anotações, fluxogramas e sincronização.

## 2. Regras

- O desktop continua sendo o produto existente.
- mobile será um projeto e repositório Git separado.
- Android será a primeira plataforma.
- A implementação será incremental e offline-first.
- Cada fase entrega uma parte demonstrável.
- O assistente explica e fornece código/comandos; o usuário escreve, executa e valida.
- Dependências só entram quando houver necessidade clara.
- Uma fase termina somente depois do checklist técnico e de aprendizado.

## 3. Estado atual

A Fase 0 já foi concluída:

- projeto Flutter em mobile;
- shell inicial com Hoje, Cards, Trilhas e Mais;
- teste básico de widget;
- análise estática, testes e build Android executados;
- mobile ignorado pelo repositório desktop para permitir Git separado.

A próxima fase é a Fase 1. Nenhum código da Fase 1 deve ser aplicado sem iniciar a aula correspondente.

---

## Fase 0 — Orientação e protótipo navegável

Aprender: estrutura Flutter, main, MaterialApp, widgets, navegação inferior, testes e build.

Entregar: shell visual navegável sem banco de dados.

Concluído quando: app abre no Android, abas funcionam, teste passa, APK debug é gerado e o autor explica o caminho desde main.

---

## Fase 1 — Dart essencial e divisão do shell

Aprender: tipos, nulabilidade, classes, construtores, composição, listas, map, separação por arquivos e testes de unidade.

Entregar: dividir o shell em tema, modelos de navegação, widgets compartilhados e telas, sem mudar o comportamento.

Exercício: desenhar a árvore de arquivos antes de copiar qualquer código e explicar a responsabilidade de cada arquivo.

Concluído quando: main apenas inicializa, cada tela tem responsabilidade clara e dart format, flutter analyze e flutter test passam.

---

## Fase 2 — Arquitetura de features e estado

Aprender: arquitetura por feature, apresentação/domínio/dados, estado local e compartilhado, Riverpod ou alternativa equivalente, injeção de dependência e estados loading/data/empty/error.

Entregar: lista de trilhas em memória com dados falsos, provider e repositório substituível por fake.

Concluído quando: UI não conhece a fonte dos dados e existe teste de estado.

---

## Fase 3 — Persistência local offline

Aprender: SQLite, tabelas, chaves, índices, migrações, repositórios, serialização, datas e IDs.

Entregar: banco local para trilhas, tópicos, subtópicos e progresso. Avaliar Drift por ser tipado e adequado ao SQLite.

Modelo mínimo: study_tracks, study_nodes, study_node_links, study_progress e sync_metadata.

Todo registro sincronizável deve ter id, createdAt, updatedAt e deletedAt quando aplicável.

Exercício: criar uma trilha, fechar o app e confirmar que ela continua presente.

Concluído quando: base e migração são documentadas, CRUD offline funciona e o repositório tem teste.

---

## Fase 4 — Trilhas e roadmaps

Aprender: árvores, recursão, ordenação, progresso derivado, operações otimistas, formulários e validação.

Entregar: criar/editar trilhas, tópicos e subtópicos ilimitados, mover irmãos, concluir, prioridade por bandeira, filtro por prioridade, anotações, criação em massa e preview antes de salvar.

Exercício: importar linhas no formato Nome | Descrição e revisar o preview.

Concluído quando: hierarquia, progresso, erros de formato e confirmação funcionam sem internet.

---

## Fase 5 — Flashcards e revisão ativa

Aprender: máquina de estados, agenda, repetição espaçada, resposta digitada, normalização e acessibilidade.

Entregar: responder digitando, exigir acerto para avançar, mostrar classificação apenas depois, agendar revisão, vincular a tópicos e abrir a origem.

Concluído quando: avaliação é previsível, persiste e possui testes para respostas inválidas.

---

## Fase 6 — Questões e simulados

Aprender: formulários complexos, alternativas, gabarito, estado de tentativa, persistência incremental, retomada e relatórios.

Entregar: cadastrar/editar questões, cadastro em massa com preview, vincular a prova/vaga, enumerar pela prova, montar simulado, salvar a cada questão, retomar de onde parou, finalizar/reabrir e mostrar acertos, erros, não respondidas, percentual, tópicos e anotações.

Exercício: interromper na questão 39 de 70, fechar o app e retornar à questão pendente.

Concluído quando: tentativa usa status explícito, pode ser retomada, resultado é reproduzível e os fluxos têm testes.

---

## Fase 7 — Materiais, PDFs e conteúdo de prova

Aprender: seleção de arquivos, permissões, cache, PDF, OCR, processamento assíncrono, progresso e cancelamento.

Entregar primeiro visualização de PDFs. Depois importação de prova/gabarito com preview, alternativas preservadas, remoção de cabeçalhos/rodapés, versão, formatação de SQL/Java/diagramas e correção manual.

Concluído quando: o usuário diferencia extração de texto e OCR, arquivos grandes não travam e nada é salvo sem confirmação.

---

## Fase 8 — Fluxogramas e vínculos visuais

Aprender: canvas, gestos, seleção em área, pan/zoom, clipboard, undo/redo e serialização de grafos.

Entregar fluxogramas vinculados a tópicos, seleção múltipla, copiar/colar/recortar, conexões e abertura nos dois sentidos.

Concluído quando: seleção, clipboard, undo/redo e vínculos funcionam previsivelmente.

---

## Fase 9 — Sincronização entre dispositivos

Aprender: sincronização incremental, versões, conflitos, tombstones, pareamento, segurança, QR code e rede local.

Entregar em ordem: pacote local, sincronização por arquivo, conflitos com versão local/recebida, manter local/usar recebida, sincronização bidirecional por ID, tombstones, pareamento por QR/rede e expiração de token.

Exercício: alterar o mesmo flashcard em dois dispositivos simulados e resolver o conflito.

Concluído quando: não há duplicação, exclusões são propagadas, conflitos não são descartados e pareamento expira.

---

## Fase 10 — Qualidade, acessibilidade e desempenho

Aprender: testes unitários, widget e integração, profiling, rebuilds, acessibilidade, erros e logs.

Entregar: cobertura dos fluxos críticos, estados vazios/erro, feedback de operações longas, fonte ampliada, navegação sem depender só de cor, listas grandes e logs sem dados sensíveis.

---

## Fase 11 — Release Android

Aprender: debug/release, assinatura, versionamento, APK/AAB, permissões, ícone e splash.

Entregar: build release assinado, instalação real, notas de release, backup, migração local e pacote de distribuição.

Concluído quando: instalação limpa e atualização preservam dados e rollback está documentado.

---

## Fase 12 — Evolução pós-MVP

Depois do MVP: iOS, servidor, login, notificações, widgets, OCR avançado, colaboração e analytics locais.

## Critério geral de conclusão

O MVP estará concluído quando for possível criar trilhas hierárquicas, acompanhar prioridades, vincular questões/flashcards/fluxogramas, estudar offline, criar e retomar simulados, consultar resultados, exportar/importar dados, sincronizar com conflitos visíveis e instalar uma release sem perder dados.