# Dunots Mobile — decisões arquiteturais

## D-001 — Mobile separado do desktop

Status: aceito.

O Flutter ficará em mobile e terá Git próprio. O desktop ignora mobile porque dependências, build e release são diferentes.

## D-002 — Android primeiro

Status: aceito.

Android reduz o escopo inicial e permite aprender o ciclo completo antes de investir em iOS.

## D-003 — Offline-first

Status: aceito.

Criar, estudar, responder e consultar resultados deve funcionar sem internet. Sincronização é complementar.

## D-004 — Persistência tipada

Status: proposto.

Avaliar Drift sobre SQLite na Fase 3 por tipagem, migrações e relações. A decisão será confirmada após um pequeno protótipo.

## D-005 — Estado por providers

Status: proposto.

Avaliar Riverpod na Fase 2 para separar UI, repositórios e testes.

## D-006 — Contrato de dados compatível

Status: aceito.

Manter IDs, datas, tombstones e versões de esquema no formato de exportação/sincronização.

## D-007 — Aprendizado primeiro

Status: aceito.

Cada fase terá explicação, exercício, implementação, validação e commit granular. Evitar abstrações prematuras.