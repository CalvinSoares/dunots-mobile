# Dunots Mobile — instruções do projeto

## Escopo

- Este diretório é um repositório Flutter independente do desktop.
- Alterações em `mobile/` não devem editar o desktop, salvo solicitação explícita.
- O produto é offline-first: o uso principal deve continuar funcionando sem internet.

## Fontes de decisão

- `README.md`: visão geral, comandos e estado da release.
- `docs/plan.md`: sequência de implementação e pendências.
- `docs/architecture.md`: camadas, persistência e limites técnicos.
- `docs/design.md`: padrão visual e regras de responsividade.
- `docs/checks.md`: validações executadas e seus resultados.
- `docs/decisions.md`: decisões arquiteturais aceitas ou propostas.
- `docs/parity.md`: comparação de funcionalidades com desktop/web.
- `.cursor/rules/`: regras automáticas de colaboração do repositório.

Quando duas descrições divergirem, atualize a documentação afetada e registre a
decisão em `docs/decisions.md` antes de criar uma nova convenção.

## Ordem segura de implementação

1. Modelos, contratos e funções puras.
2. Repositórios e migrações.
3. Componentes e telas de feature.
4. Shell, injeção de dependências e ponto de entrada.
5. Testes da unidade alterada e testes de integração afetados.
6. Documentação e validação final.

Não importar um arquivo antes de ele existir. Manter produção em `lib/` e testes
em `test/`.

## Padrão de interface

- Seguir `docs/design.md` antes de criar cores, espaçamentos ou componentes novos.
- Preferir tokens de `DunotsColors` e o tema global a cores literais.
- Usar uma ação primária por seção; ações secundárias devem ser compactas.
- Botões de ícone precisam de `tooltip` e ações importantes precisam de rótulo.
- Garantir alvo de toque confortável, texto curto e layout válido em telas de
  360 px de largura e em landscape.
- Não usar `Expanded` dentro de eixos com altura não limitada, como colunas dentro
  de `SingleChildScrollView`.
- Loading, erro e vazio devem ser centralizados quando ocuparem uma tela inteira;
  erros precisam oferecer retry quando a operação puder ser repetida.

## Persistência e compatibilidade

- Usar repositórios, não acessar SQLite diretamente na UI.
- Toda alteração de schema precisa de migração e teste de banco antigo.
- Preservar IDs, datas, campos opcionais, versões de contrato e tombstones do
  sincronizador desktop/mobile.

## Validação

Executar o conjunto adequado à alteração:

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

O build de release deve ser executado quando a alteração afetar Android,
dependências, versão ou distribuição.

## Git e entrega

- O assistente implementa, testa e revisa; o usuário executa commits e push.
- Nunca criar commits nem fazer push automaticamente.
- Entregar comandos de commits granulares, separados por responsabilidade e,
  preferencialmente, com no máximo cinco arquivos por commit.
- Não usar `git add .`; listar explicitamente os arquivos.
- Documentação em `docs/` é mantida localmente e permanece ignorada pelo Git.
