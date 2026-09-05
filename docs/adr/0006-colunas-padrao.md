# ADR-0006 — Colunas padrão e soft delete nas tabelas de negócio

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §19.2, §19.6, §25 ("Confiabilidade"), §26.4

## Contexto

A sincronização (§19) exige, em todo registro de servidor: `version`,
`created_at`, `updated_at`, `deleted_at`, `created_by`, `updated_by`. Exclusão
usa tombstone (`deleted_at`) durante uma janela de retenção (§19.6) — exclusão
física imediata faz outro dispositivo recriar o registro. Queremos um formato
único para não repetir a decisão em cada tabela.

## Decisão

### Conjunto de colunas padrão

Toda tabela de dados de `app.*` (tenant-scoped ou de configuração da organização)
inclui:

```sql
version     integer     not null default 1,
created_at  timestamptz not null default now(),
updated_at  timestamptz not null default now(),
deleted_at  timestamptz,
created_by  uuid,
updated_by  uuid,
deleted_by  uuid
```

`*_by` referenciam `iam.users(id)` logicamente, **sem** FK física (o ator pode ser
um processo de sistema; evita acoplar `app` a `iam` em cascata). Ficam anuláveis:
o bootstrap da primeira organização não tem usuário ainda.

Tabelas de referência **globais** (`app.permission_catalog`, `app.role_templates`,
`app.role_template_permissions`) não são de organização e usam apenas
`created_at`/`updated_at` — não entram no protocolo de sync nem em soft delete.

`iam.*` mantém suas próprias colunas conforme a spec §15–§16 (ex.: `sessions` tem
`revoked_at`/`revoke_reason`, não `deleted_at`); não segue este padrão.

### Manutenção por trigger

`app.set_row_defaults()` (`BEFORE INSERT OR UPDATE`, plpgsql):

- **INSERT:** `created_at`/`updated_at` = `now()`; `created_by`/`updated_by` =
  `current_setting('app.user_id', true)` quando não informados; `version` = 1.
- **UPDATE:** `updated_at` = `now()`; `updated_by` = ator; `version` =
  `OLD.version + 1`; `created_at`/`created_by` preservados (não podem ser
  alterados pela aplicação).
- **Soft delete** (`NEW.deleted_at` passou de null para não-null): `deleted_by` =
  ator.
- **Undelete** (`deleted_at` volta a null): `deleted_by` = null.

Cliente e endpoints nunca enviam `version`/`*_at`/`*_by` — são derivados.
Concorrência otimista (§19.5): o `UPDATE` da aplicação carrega
`WHERE id = $1 AND version = $baseVersion`; 0 linhas afetadas = conflito.

### Unicidade com soft delete

Índices únicos de negócio são **parciais**: `... WHERE deleted_at IS NULL`.
Um registro tombstoned não bloqueia recriar a mesma chave natural.

## Alternativas consideradas

- **`DELETE` físico + tabela de tombstones separada** — mais uma tabela para
  sincronizar e manter em par; o `deleted_at` na própria linha é o padrão de
  mercado para sync offline.
- **Colunas mantidas na aplicação (sqlc)** — fácil esquecer em um caminho;
  o trigger garante a invariante mesmo em correção manual.
- **`version` como `xmin`/timestamp** — `xmin` não sobrevive a `VACUUM FULL`/dump;
  inteiro monotônico por linha é explícito e portável para o SQLite do cliente.

## Consequências

- `internal/db` (sqlc) lê essas colunas mas não as escreve; helpers de repositório
  aplicam o `WHERE version = $base` nos updates.
- Todo `SELECT` de negócio precisa de `AND deleted_at IS NULL` (ou uma view) —
  padronizar nos `queries/*.sql`.
- A RLS (ADR-0003) age sobre linhas tombstoned normalmente; expurgo pós-retenção
  é job de background com contexto de organização (Fase 6/7).
- Retenção de tombstones fica em aberto (spec §30) — default provisório sugerido:
  90 dias, configurável por organização depois.
