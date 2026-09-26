# Dunots Mobile — arquitetura-alvo

## Princípios

1. Offline-first.
2. Organização por feature.
3. UI não acessa SQLite, arquivos ou rede diretamente.
4. Modelos de domínio, persistência e transporte são explícitos.
5. Regras de negócio devem ser testáveis sem abrir uma tela.
6. Camadas só entram quando resolverem um problema real.

## Estrutura proposta

    mobile/
      lib/
        main.dart
        app/
        core/
          database/
          errors/
          models/
          storage/
          sync/
          utils/
          widgets/
        features/
          home/
          flashcards/
          trilhas/
          questoes/
          simulados/
          fluxogramas/
          materiais/
          settings/
        shared/
      test/

## Camadas

Apresentação: widgets, telas, formulários e providers/controllers.

Domínio: entidades, regras e casos de uso como calcular progresso, normalizar resposta e resolver conflito. Não depende de Flutter ou SQLite.

Dados: implementações de repositórios para banco local, arquivos e sincronização.

## Persistência

Avaliar Drift sobre SQLite na Fase 3 por tipagem, migrações e relações.

Registros sincronizáveis devem ter:

    id
    createdAt
    updatedAt
    deletedAt opcional
    deviceId

deletedAt é um tombstone e não deve ser removido antes dos dispositivos receberem a exclusão.

## Estado

Usar estados explícitos: initial, loading, data, empty, error e saving.

Riverpod é a recomendação inicial para a Fase 2, mas será confirmado após um protótipo.

## Sync

Envelope de transporte previsto:

    schemaVersion
    sourceDeviceId
    createdAt
    records
    tombstones
    checksum opcional

Conflitos devem ser apresentados quando a resolução automática puder perder informação.

## Compatibilidade desktop/mobile

Não compartilhar UI. Compartilhar somente depois de estabilizado: entidades, IDs, datas, formato de exportação, tombstones e documentação. Cada produto continua podendo evoluir e compilar separadamente.