# ADR-0003 — Estratégia de isolamento multitenant (RLS)

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §14, §21, §26.1, §29 (item 2)

## Contexto

Banco compartilhado, tabelas compartilhadas, `organization_id` em todo dado de
organização. A RLS do PostgreSQL é exigida como defesa adicional (§14.3), sem
substituir os testes de isolamento nem a autorização no código.

## Decisão

### Dois papéis no PostgreSQL

- `servory_owner` — dono de todos os schemas e tabelas; executa migrations.
- `servory_app` — usado pela aplicação em runtime. `NOSUPERUSER`, **`NOBYPASSRLS`**,
  não é dono das tabelas, não pode `ALTER TABLE ... DISABLE ROW LEVEL SECURITY`.

Os papéis são criados fora das migrations, por script de provisionamento
(`deploy/postgres/initdb/00-roles.sh` em dev; passo manual único na VPS). As
migrations rodam como `servory_owner` e concedem DML ao `servory_app` via
`ALTER DEFAULT PRIVILEGES`.

### Contexto por transação

Todo acesso tenant-scoped passa por `postgres.WithTenantTx`, que numa transação
executa:

```sql
SELECT set_config('app.organization_id', $1, true);
SELECT set_config('app.user_id', $2, true);
```

(`set_config(..., true)` = `SET LOCAL`, escopo da transação.)

### Policies

Tabelas tenant-scoped de `app.*` recebem:

```sql
ALTER TABLE app.<t> ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.<t> FORCE ROW LEVEL SECURITY;
CREATE POLICY <t>_tenant_isolation ON app.<t>
  USING      (organization_id = current_setting('app.organization_id')::uuid)
  WITH CHECK (organization_id = current_setting('app.organization_id')::uuid);
```

### Exceção: `app.organization_memberships`

O login precisa listar as associações de um usuário **antes** de existir uma
organização ativa. A policy dessa tabela aceita as duas formas de contexto:

```sql
CREATE POLICY memberships_access ON app.organization_memberships
  USING (
    organization_id = current_setting('app.organization_id', true)::uuid
    OR user_id = current_setting('app.user_id', true)::uuid
  );
```

Consultas de identidade usam `postgres.WithUserTx` (define só `app.user_id`).

## Alternativas consideradas

- **Schema ou banco por organização:** proibido pela spec no MVP (§14.1);
  operação e migrations não escalam.
- **Somente filtro na aplicação, sem RLS:** a spec exige RLS como camada extra;
  um bug de `WHERE` não pode vazar dados de outro tenant.
- **Função `SECURITY DEFINER` para o login ler memberships:** mais superfície de
  auditoria; a policy dupla é mais simples e explícita.

## Consequências

- Toda query de negócio **deve** abrir `WithTenantTx`; queries fora dele só
  enxergam dados se a tabela não tiver RLS (tabelas globais de `iam`).
- Jobs em background precisam de contexto explícito de organização (§14.2).
- Testes obrigatórios (§26.1): query sem contexto retorna 0 linhas; `WITH CHECK`
  barra `INSERT`/`UPDATE` com `organization_id` divergente; busca por UUID de
  outro tenant retorna vazio.
- `iam.users`, `iam.sessions`, `iam.refresh_tokens` são globais/por-usuário e
  **não** usam RLS; sua proteção é a aplicação filtrando por `user_id` extraído
  do token verificado.
