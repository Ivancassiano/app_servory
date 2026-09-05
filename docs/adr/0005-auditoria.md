# ADR-0005 — Auditoria em duas camadas

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §23, §26, §29 (item 1), §25 ("Observabilidade")

## Contexto

A spec (§23) exige registro append-only de operações sensíveis: login/logout,
sessões, convites, mudança de perfil/permissão, alteração de cadastros, ordens,
lotes de etiquetas, conflitos e exportações. Precisamos de dois níveis:

1. **Forense / imutável** — "o que mudou nesta linha, quando e por quem",
   independente da aplicação lembrar de registrar. Cobre alterações feitas por
   qualquer caminho (endpoint, job, correção manual do owner).
2. **Semântico** — "o usuário X finalizou a ordem Y", com `action` estável,
   `resource_type`, `metadata` e `request_id`, consumível por telas de auditoria
   e alertas.

Registrar só no nível da aplicação deixa buracos (um `UPDATE` esquecido não
aparece); registrar só no nível de linha não dá contexto de negócio.

## Decisão

### Camada 1 — `audit.row_history` (trigger, coluna a coluna, imutável)

Uma linha por **coluna alterada** em toda tabela versionada de `iam.*` e `app.*`.

```text
audit.row_history
- id              bigint identity
- table_schema    text
- table_name      text
- row_id          uuid           -- PK da linha afetada (todas as tabelas usam id uuid)
- operation       char(1)        -- 'I' | 'U' | 'D'
- column_name     text
- old_value       jsonb          -- null em INSERT
- new_value       jsonb          -- null em DELETE
- organization_id uuid           -- current_setting('app.organization_id')
- actor_user_id   uuid           -- current_setting('app.user_id')
- actor_device_id uuid           -- current_setting('app.device_id')
- request_id      uuid           -- current_setting('app.request_id')
- occurred_at     timestamptz default now()
```

- `INSERT`: uma linha por coluna não-nula, `old_value` null.
- `UPDATE`: uma linha por coluna cujo valor mudou (`IS DISTINCT FROM`).
- `DELETE`: uma linha por coluna não-nula, `new_value` null. Como o padrão é
  soft delete (ADR-0006), o `DELETE` físico só ocorre em expurgo administrativo.

Função genérica `audit.capture_row_change()` (plpgsql, `SECURITY INVOKER`) anexada
via `AFTER INSERT OR UPDATE OR DELETE ... FOR EACH ROW`. Um trigger
`audit_row_history` por tabela auditada.

### Camada 2 — `audit.audit_events` (eventos semânticos, pela aplicação)

Estrutura da spec §21/§23:

```text
audit.audit_events
- id              uuid
- organization_id uuid null      -- null em eventos pré-organização (falha de login)
- actor_user_id   uuid null
- actor_device_id uuid null
- action          text           -- 'auth.login', 'session.revoked', 'role.updated', ...
- resource_type   text null
- resource_id     uuid null
- metadata        jsonb not null default '{}'
- request_id      uuid null
- occurred_at     timestamptz not null default now()
```

Inserida pela aplicação por meio da função `audit.log_event(action, resource_type,
resource_id, metadata)`, que preenche ator/organização/device/request a partir dos
GUCs da transação. A aplicação também pode `INSERT` direto quando não há contexto
de transação de tenant (ex.: falha de login antes de sessão).

### Append-only

Ambas as tabelas de `audit.*`:

- `servory_app` recebe apenas `SELECT, INSERT` (já é o default do ADR-0003 /
  migration 00001; nenhum `UPDATE`/`DELETE`/`TRUNCATE`).
- Trigger `BEFORE UPDATE OR DELETE OR TRUNCATE` que executa `RAISE EXCEPTION` —
  barra inclusive o `servory_owner` na operação normal. Expurgo por retenção é
  feito por função dedicada e explicitamente auditada (fora do MVP).

### GUCs adicionais na transação

`postgres.WithTenantTx` passa a definir também, quando presentes:

```sql
SELECT set_config('app.device_id',  $1, true);
SELECT set_config('app.request_id', $1, true);
```

Todos parametrizados (nunca concatenados) — ver `docs/sql-safety.md`.

## Alternativas consideradas

- **Uma linha por operação com `row_before`/`row_after` jsonb** — mais compacta,
  mas "coluna a coluna" (§23) fica implícito e consultas por campo específico
  ("quem alterou o custo") exigem varrer jsonb. Rejeitada em favor da forma
  explícita.
- **Só `audit_events` na aplicação** — não cobre alterações fora do caminho
  esperado; a spec pede imutabilidade real.
- **Extensão `pgaudit`** — audita comandos no log do servidor, não em tabela
  consultável por organização; complementar, não substituto.

## Consequências

- Toda tabela versionada ganha um trigger de história; escritas ficam um pouco
  mais caras (aceitável no volume do MVP).
- `row_history` cresce rápido em tabelas quentes — política de retenção/particionamento
  entra no hardening (Fase 7); a decisão de retenção fica em aberto (spec §30).
- Testes (§26): alteração de campo sensível aparece em `row_history`; `audit_events`
  registra a sequência de conflito de etiqueta; `UPDATE`/`DELETE` em `audit.*` falha.
- Jobs em background precisam abrir contexto de transação com `app.user_id` (ou um
  ator de sistema) para que a história tenha autor.
