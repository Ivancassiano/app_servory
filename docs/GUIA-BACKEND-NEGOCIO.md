# Guia: construir o backend de negócio sobre a fundação de auth

> **Para quem:** o desenvolvedor (humano ou Claude) que vai criar
> `cmd/servicelog-api` e os módulos de negócio (clientes, locais, equipamentos,
> ordens, etiquetas, sincronização) nas Fases 3–6 da spec.
>
> **Ponto de partida:** a branch `feature/auth-foundation` está completa (M0–M6)
> e entrega toda a segurança (identidade, multitenancy, RLS, permissões,
> auditoria). Este guia mostra **como consumir** essa fundação sem reimplementar
> nada e **quais convenções seguir** para o código novo ficar consistente.
>
> Ordem de leitura recomendada: este guia → `docs/adr/` (0002, 0003, 0005, 0006,
> 0009, 0010) → `servicelog-especificacao-funcional-tecnica.md` §13–§22, §26.

---

## 0. TL;DR — as 6 regras

1. **Toda rota autenticada** passa por `iamSvc.Authenticator` e lê o ator com
   `iam.PrincipalFrom(ctx)`.
2. **Todo acesso a tabela de `app.*`** acontece dentro de
   `resolver.Authorize(ctx, principal.TenantContext(reqID), "<permissão>", fn)`
   — que abre a transação com contexto de tenant (RLS), checa a permissão e
   roda `fn` na mesma transação.
3. **Nunca monte SQL com string.** `sqlc` para tudo; `tx.Exec(ctx, "SELECT
   audit.log_event(...)", $1)` só com texto literal + `$N`. Ver
   `docs/sql-safety.md`.
4. **Toda tabela de negócio** tem as colunas padrão (ADR-0006), RLS
   `ENABLE`+`FORCE` (ADR-0003) e os dois triggers (`set_row_defaults`,
   `audit_row_history`).
5. **Campos sensíveis** passam por `Effective.FilterReadable` (saída) e
   `Effective.UnauthorizedWrites` (entrada). Chave nova = negada por padrão.
6. **Toda permissão nova** entra em `app.permission_catalog` por migration de
   seed **antes** de poder ser concedida (há FK).

---

## 1. O que a fundação já entrega

Módulo Go: `github.com/ivancassiano/auth_servory`. Binário novo: `cmd/servicelog-api`.

| Pacote | O que reusar |
|---|---|
| `internal/platform/postgres` | `DB.WithTenantTx`, `DB.WithUserTx`, `DB.Pool()`, `TenantContext` |
| `internal/platform/tokens` | `LoadVerifyKeySet` (só verifica), `NewIssuer`, `Issuer.Verify` |
| `internal/platform/httpx` | `NewRouter`, `WriteJSON`, `WriteError`, `DecodeJSON`, `Error`/`Errorf`, `RateLimitByIP`, `TrustForwardedFor`, `Health` |
| `internal/platform/{config,clock,id,log,valkey,mail}` | infra transversal |
| `internal/iam` | `Principal`, `PrincipalFrom`, `Service.Authenticator` (middleware) |
| `internal/permissions` | `Resolver` (`Authorize`, `Effective`, `EffectiveFor`), `Effective` (`Can`, `CanReadField`, `FilterReadable`, `UnauthorizedWrites`), `ErrForbidden` |
| `internal/audit` | consulta (`/v1/audit`); a **escrita** é a função SQL `audit.log_event(...)` |
| `internal/mailq` | `NewEnqueuer` (fila de e-mail); `NewDispatcher` no worker |
| `internal/db` | código `sqlc` — **regenerado**, não editar |
| `internal/testsupport/testdb` | `New(t)`, `Env.Store`, `Env.Admin`, `SeedUser/SeedOrg/SeedRole/SeedMembership`, `Truncate` |

O schema (`migrations/00001..00007`) já tem `iam.*`, `app.*` (org/perfis/permissões),
`audit.*`, os papéis `servory_owner`/`servory_app`, as funções
`app.current_org()`/`app.current_actor()`/`app.set_row_defaults()`/`audit.capture_row_change()`/`audit.log_event()`.

---

## 2. Como o `servicelog-api` valida o token

O `auth-api` **emite** o JWT (EdDSA) com `aud = servicelog-api`. O `servicelog-api`
só **verifica** — recebe apenas as chaves públicas (`*.pub.pem`), spec §16.1.

```go
keys, err := tokens.LoadVerifyKeySet(cfg.Tokens.KeyDir)          // só *.pub.pem
issuer := tokens.NewIssuer(keys, cfg.Tokens.Issuer, cfg.Tokens.Audience, 0, clock.System{})
// issuer.Verify(raw) funciona; issuer.Issue(...) falha (sem chave privada) — correto.
```

O middleware de autenticação: você pode **reusar `iam.Service.Authenticator`**
(ele já faz JWT + checagem de sessão revogada no Valkey com fallback Postgres)
montando um `iam.Service` com as mesmas deps, **ou** escrever um middleware
enxuto no `servicelog-api` que só chama `issuer.Verify` + monta o `Principal`.
Recomendado: reusar `iam.Service.Authenticator` para herdar a checagem de sessão.

> **Pendência conhecida (ADR / progresso):** hoje o `auth-api` valida os
> próprios endpoints com `aud=servicelog-api`. Quando o `servicelog-api` existir,
> decidir se o `auth-api` passa a usar uma audiência própria. Não bloqueia.

---

## 3. Os 5 conceitos que você vai usar em TODO handler de negócio

### 3.1 `Principal` — quem está pedindo

```go
p, ok := iam.PrincipalFrom(r.Context())   // depois do middleware Authenticator
// p.UserID, p.OrganizationID, p.DeviceID, p.SessionID, p.PermissionVersion
tc := p.TenantContext(requestID)           // -> postgres.TenantContext p/ a transação
```

`requestID`: `uuid.Parse(httpx.RequestIDFromContext(r.Context()))` (o middleware
`RequestID` garante que é um UUID).

### 3.2 `WithTenantTx` — RLS ligada

```go
err := db.WithTenantTx(ctx, tc, func(tx pgx.Tx) error {
    q := dbgen.New(tx)                      // sqlc ligado à transação
    // aqui, RLS filtra automaticamente por p.OrganizationID.
    // audit.capture_row_change() grava a história com ator/org/device/request.
    return nil
})
```

- Fora de `WithTenantTx`, uma query em `app.*` retorna **0 linhas** (RLS `FORCE`).
- `WithTenantTx` exige `OrganizationID != uuid.Nil`.
- Faz commit em sucesso, rollback em erro **ou panic**.

### 3.3 `Resolver.Authorize` — checagem + ação atômicas (o padrão preferido)

```go
resolver := permissions.NewResolver(db, valkeyClient) // valkeyClient pode ser nil

err := resolver.Authorize(ctx, tc, "client.update", func(tx pgx.Tx) error {
    q := dbgen.New(tx)
    // só chega aqui se p tem a permissão "client.update".
    // mesma transação: checagem e escrita não têm janela de corrida.
    return q.UpdateClient(ctx, ...)
})
// err == permissions.ErrForbidden  -> 403
```

Para checagens fora de um handler (ex.: montar payload), use
`resolver.EffectiveFor(ctx, tc)` e depois `eff.Can("...")`.

### 3.4 Máscara de campo (spec §17.4)

O motor já entende `{recurso}.{campo}.{read|write}`. Um campo fora do
`permission_catalog` **nunca** é concedido (default deny → "campo novo inicia
negado" de graça).

```go
// declare o mapa uma vez por recurso: chave-JSON -> nome-de-campo-no-catálogo
var clientFields = map[string]string{
    "name":           "name",
    "phone":          "phone",
    "internal_notes":  "internal_notes",
    "tax_id":         "tax_id",
}

// LEITURA: remova campos que o ator não pode ler
eff, _ := resolver.Effective(ctx, tx, tc.OrganizationID, tc.UserID)
payload := clientToMap(row)                 // map[string]any
eff.FilterReadable("client", payload, clientFields)
httpx.WriteJSON(w, 200, payload)

// ESCRITA: rejeite a requisição inteira se tocar campo sem permissão
bad := eff.UnauthorizedWrites("client", incomingMap, clientFields)
if len(bad) > 0 {
    httpx.WriteError(w, r, httpx.Errorf(422, "FIELD_FORBIDDEN",
        "Campos não permitidos: "+strings.Join(bad, ", ")))
    return
}
```

Regra de leitura de recurso (`client.read`) vem antes: sem ela, 403 e nem chega
na máscara de campo.

### 3.5 Auditoria — evento semântico

Dentro da transação, após a operação:

```go
_, err = tx.Exec(ctx,
    `SELECT audit.log_event('client.created', 'client', $1, $2::jsonb)`,
    clientID, metadataJSON)   // metadataJSON = []byte de json.Marshal, ou '{}'
```

- `action` e `resource_type` são **literais** que você escolhe (spec §23 lista os
  mínimos: criação/alteração de cliente/local/equipamento, finalização de ordem,
  emissão/reimpressão de lote, atribuição/rejeição/substituição de etiqueta,
  resolução de conflito, exportação).
- Ator/organização/device/request são preenchidos pela função a partir dos GUCs
  da transação — você não passa.
- A história **coluna a coluna** (`audit.row_history`) é automática via trigger;
  `log_event` é só a camada semântica.
- **Nunca** logue senha, token, chave ou conteúdo sensível completo (spec §23).

---

## 4. Receita: adicionar uma entidade de negócio de ponta a ponta

Exemplo: `client`. Replique o molde para `location`, `equipment_type`,
`equipment`, etc.

### Passo 1 — Migration do schema

`migrations/00008_clients.sql`:

```sql
-- +goose Up
CREATE TABLE app.clients (
  id              uuid PRIMARY KEY,
  organization_id uuid NOT NULL REFERENCES app.organizations (id) ON DELETE CASCADE,
  name            text NOT NULL,
  tax_id          text NOT NULL DEFAULT '',
  phone           text NOT NULL DEFAULT '',
  email           text NOT NULL DEFAULT '',
  contact_person  text NOT NULL DEFAULT '',
  internal_notes  text NOT NULL DEFAULT '',
  -- colunas padrão (ADR-0006) — SEMPRE estas 7:
  version     integer     NOT NULL DEFAULT 1,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz,
  created_by  uuid,
  updated_by  uuid,
  deleted_by  uuid
);

-- índices (spec §21): org sempre; busca por nome dentro da org
CREATE INDEX clients_org_idx  ON app.clients (organization_id);
CREATE INDEX clients_name_trgm ON app.clients USING gin (name gin_trgm_ops);  -- pg_trgm já habilitado

-- trigger de colunas padrão
CREATE TRIGGER clients_row_defaults BEFORE INSERT OR UPDATE ON app.clients
  FOR EACH ROW EXECUTE FUNCTION app.set_row_defaults();

-- RLS (ADR-0003)
ALTER TABLE app.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.clients FORCE ROW LEVEL SECURITY;
CREATE POLICY clients_tenant_isolation ON app.clients
  USING      (organization_id = app.current_org())
  WITH CHECK (organization_id = app.current_org());

-- trigger de auditoria (história coluna a coluna)
CREATE TRIGGER audit_row_history AFTER INSERT OR UPDATE OR DELETE ON app.clients
  FOR EACH ROW EXECUTE FUNCTION audit.capture_row_change();

-- +goose Down
DROP TABLE IF EXISTS app.clients;
```

Convenções de migration:
- goose; `-- +goose Up` / `-- +goose Down`; sempre com `Down` reversível.
- `-- +goose StatementBegin` / `-- +goose StatementEnd` em volta de `CREATE FUNCTION`
  / `DO $$` (qualquer bloco com `;` interno).
- FK sempre inclui `organization_id` quando há risco de relação cruzada (spec §14.2).
- **Não** ponha o nome da tabela no array de `00005` — cada migration nova
  anexa os próprios triggers (como acima).

### Passo 2 — Permissões no catálogo

`migrations/00009_seed_client_permissions.sql` (ou adicione ao seed de negócio):

```sql
-- +goose Up
INSERT INTO app.permission_catalog (key, resource, action, is_field, description) VALUES
  ('client.read',   'client', 'read',   false, 'Ver clientes'),
  ('client.create', 'client', 'create', false, 'Cadastrar cliente'),
  ('client.update', 'client', 'update', false, 'Editar cliente'),
  ('client.delete', 'client', 'delete', false, 'Remover cliente'),
  ('client.name.read',           'client', 'read',  true, 'Ver nome do cliente'),
  ('client.name.write',          'client', 'write', true, 'Editar nome do cliente'),
  ('client.internal_notes.read', 'client', 'read',  true, 'Ver notas internas'),
  ('client.internal_notes.write','client', 'write', true, 'Editar notas internas')
ON CONFLICT (key) DO NOTHING;

-- conceda aos templates (o bootstrap materializa nas orgs existentes só via novo bootstrap;
-- para orgs já criadas, rode um backfill — ver nota abaixo)
INSERT INTO app.role_template_permissions (template_key, permission_key, effect)
SELECT 'admin', key, 'allow' FROM app.permission_catalog WHERE key LIKE 'client.%'
ON CONFLICT DO NOTHING;
INSERT INTO app.role_template_permissions (template_key, permission_key, effect)
SELECT 'viewer', key, 'allow' FROM app.permission_catalog WHERE key LIKE 'client.%' AND action = 'read'
ON CONFLICT DO NOTHING;
INSERT INTO app.role_template_permissions (template_key, permission_key, effect)
SELECT 'technician', key, 'allow' FROM app.permission_catalog
WHERE key IN ('client.read','client.create','client.update','client.name.read','client.name.write')
ON CONFLICT DO NOTHING;
-- +goose Down
DELETE FROM app.permission_catalog WHERE key LIKE 'client.%';
```

> **Backfill de perfis `is_system` existentes:** `role_template_permissions` só
> afeta orgs criadas **depois**. Para dar as novas permissões aos perfis
> `admin`/`viewer`/`technician` já materializados, a migration deve também:
> `INSERT INTO app.role_permissions (id, organization_id, role_id, permission_key, effect)
> SELECT gen_random_uuid(), r.organization_id, r.id, tp.permission_key, tp.effect
> FROM app.roles r JOIN app.role_template_permissions tp ON tp.template_key = r.key
> WHERE r.is_system AND tp.permission_key LIKE 'client.%'
> ON CONFLICT DO NOTHING;` e depois
> `UPDATE app.organization_memberships SET permission_version = permission_version + 1;`

### Passo 3 — Queries sqlc

`internal/db/queries/clients.sql`:

```sql
-- name: GetClient :one
SELECT * FROM app.clients WHERE id = $1 AND deleted_at IS NULL;

-- name: ListClients :many
SELECT * FROM app.clients
WHERE deleted_at IS NULL
ORDER BY name
LIMIT $1 OFFSET $2;

-- name: CreateClient :one
INSERT INTO app.clients (id, organization_id, name, tax_id, phone, email, contact_person, internal_notes)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING *;

-- name: UpdateClient :one
UPDATE app.clients
SET name = $3, tax_id = $4, phone = $5, email = $6, contact_person = $7, internal_notes = $8
WHERE id = $1 AND version = $2 AND deleted_at IS NULL   -- trava otimista (spec §19.5)
RETURNING *;

-- name: SoftDeleteClient :exec
UPDATE app.clients SET deleted_at = now() WHERE id = $1 AND deleted_at IS NULL;
```

Depois: `go tool sqlc generate` e commite `internal/db/*.sql.go`. **Nunca** edite
o gerado. `sqlc.yaml` já aponta `schema: "migrations"` — ele lê o schema todo.

Convenções sqlc:
- `SELECT *` é ok; sempre `AND deleted_at IS NULL` no que é soft-deletable.
- Update editável carrega `WHERE id = $1 AND version = $base` → 0 linhas = conflito
  (o handler devolve 409).
- **Não** escreva `version`/`*_at`/`*_by` — o trigger cuida.

### Passo 4 — Serviço + handlers

`internal/clients/service.go` e `internal/clients/http.go`, espelhando
`internal/organizations` / `internal/permissions`:

```go
type Service struct {
    db    *postgres.DB
    perms *permissions.Resolver
    ids   id.Generator
    log   *slog.Logger
}

func (s *Service) Create(ctx context.Context, p iam.Principal, reqID uuid.UUID, in CreateInput) (View, error) {
    var out View
    err := s.perms.Authorize(ctx, p.TenantContext(reqID), "client.create", func(tx pgx.Tx) error {
        q := db.New(tx)
        // (opcional) máscara de escrita nos campos sensíveis do in
        row, err := q.CreateClient(ctx, db.CreateClientParams{
            ID: s.ids.New(), OrganizationID: p.OrganizationID,
            Name: in.Name, /* ... */
        })
        if err != nil { return err }
        if _, err := tx.Exec(ctx,
            `SELECT audit.log_event('client.created', 'client', $1, '{}'::jsonb)`, row.ID); err != nil {
            return err
        }
        out = toView(row)
        return nil
    })
    return out, err
}
```

`http.go`: `Routes(r chi.Router, authn Middleware)` idêntico ao molde de
`internal/permissions/http.go`:
- `s.principal(w, r)` → 401 se ausente
- `httpx.DecodeJSON(r, &body)` (já com `DisallowUnknownFields` + limite de 1 MiB)
- mapeie os erros de domínio → `httpx.Error` num `writeErr` (por ora copie o
  padrão; há um item de dívida para unificar isso num helper `httpx`)
- respostas: `httpx.WriteJSON(w, 200/201, view)` ou `w.WriteHeader(204)`

### Passo 5 — Montar no binário

`cmd/servicelog-api/deps.go` + `main.go` copiando `cmd/auth-api`:
- `httpx.NewRouter` + `httpx.Health` + `httpx.TrustForwardedFor(cfg.TrustProxy)`
- `r.Route("/v1", ...)` com `r.Use(httpx.RateLimitByIP(vk, cfg.RateLimitPerIP, cfg.RateLimitWindow))` (só se `vk != nil`)
- `clientsSvc.Routes(r, iamSvc.Authenticator)`
- `http.Server` com os timeouts (`ReadTimeout` 15s, `WriteTimeout` 30s, `IdleTimeout` 60s)

### Passo 6 — Testes

`internal/clients/clients_test.go` (`package clients_test`):

```go
func TestMain(m *testing.M) {
    passwords.Default = passwords.Profile{Memory: 8<<10, Iterations: 1, Parallelism: 1, SaltLen: 16, KeyLen: 32}
    os.Exit(m.Run())
}
```

- `env := testdb.New(t)` — dá `env.Store` (`*postgres.DB` como `servory_app`) e
  `env.Admin` (pool owner, p/ asserções em tabelas **sem** RLS; para tabelas com
  RLS, asserte via `env.Store.WithTenantTx`).
- Bootstrap um org/admin: `organizations.New(...).Bootstrap(ctx, ...)`.
- **Testes obrigatórios (spec §26.1):** admin de A não lista clientes de B; busca
  por UUID de B no contexto de A = not found; `INSERT` com `organization_id` de B
  no contexto de A falha (WITH CHECK); query sem contexto = 0 linhas.
- **§26.2:** campo sem `.read` não volta; campo sem `.write` é rejeitado; negação
  do usuário prevalece; campo fora do catálogo é negado.
- Rode com `TEST_POSTGRES_APP_DSN`, `TEST_POSTGRES_MIGRATION_DSN` (e
  `TEST_VALKEY_ADDR` p/ cache). O `testdb` serializa os pacotes com advisory lock.
- **Adicione a nova tabela em `internal/testsupport/testdb/testdb.go`**
  (`truncateSQL`) para os testes limparem entre si.

---

## 5. Colunas padrão, soft delete, versão — o contrato (ADR-0006)

| Coluna | Quem preenche | Regra |
|---|---|---|
| `version` | trigger | `1` no insert; `OLD.version + 1` no update |
| `created_at` / `created_by` | trigger | imutáveis após o insert |
| `updated_at` / `updated_by` | trigger | a cada update, do contexto da transação |
| `deleted_at` | **você** (soft delete) | `SET deleted_at = now()` |
| `deleted_by` | trigger | quando `deleted_at` passa de null → não-null |

- **Soft delete é o padrão** (tombstone, spec §19.6). `DELETE` físico só em
  expurgo administrativo.
- Índices únicos de negócio são **parciais**: `... WHERE deleted_at IS NULL`.
- Trava otimista: `WHERE id = $1 AND version = $base`; 0 linhas → 409
  `VERSION_CONFLICT`.
- Sincronização (Fase 6): o cliente manda `base_version`; `version`/`updated_at`
  do servidor voltam na resposta.

---

## 6. O que **NÃO** fazer

- ❌ Aceitar `organization_id` do corpo/query para trocar o tenant. O tenant vem
  **sempre** de `p.OrganizationID` (spec §1.5, §14.2, §22.1).
- ❌ Query em `app.*` fora de `WithTenantTx` esperando ver linhas.
- ❌ Montar SQL com `fmt.Sprintf` / `+` / `strings.Builder`. `scripts/check-sql.sh`
  quebra o CI.
- ❌ Editar `internal/db/*.sql.go` (gerado).
- ❌ Confiar na UI para esconder campo — o backend mascara (`FilterReadable`).
- ❌ Conceder uma permissão que não está em `app.permission_catalog` (FK falha).
- ❌ `DELETE` em `audit.*` (barrado por trigger; só `audit.purge_older_than`).
- ❌ Resolver conflito de QR Code por merge/transferência/exclusão (spec §12 —
  regra imutável: a primeira associação confirmada vence).
- ❌ Usar Valkey como fonte de verdade (spec §20). Queda do Valkey = degrada, não
  perde dado.

---

## 7. Config / env que o `servicelog-api` precisa

Reusa `config.Load()`. Variáveis relevantes (ver `.env.example`):

```
POSTGRES_DSN                 # papel servory_app
VALKEY_ADDR                  # opcional (cache de permissões); sem ele, degrada
TOKEN_ISSUER / TOKEN_AUDIENCE
TOKEN_KEY_DIR                # só *.pub.pem para este serviço
RATE_LIMIT_PER_IP / RATE_LIMIT_WINDOW
TRUST_PROXY                  # true só atrás de proxy que sobrescreve XFF
MAIL_ASYNC                   # se o serviço mandar e-mail, use a fila (mailq.Enqueuer)
```

`POSTGRES_MIGRATION_DSN` (papel `servory_owner`) só para rodar migrations.

---

## 8. Decisões abertas a resolver antes de ir fundo (spec §30)

| Decisão | Bloqueia | Sugestão |
|---|---|---|
| Criptografia do SQLite no Flutter | Fase 2 (banco local) | avaliar SQLCipher via `sqlcipher_flutter_libs` / `drift` |
| Algoritmo e tamanho do código textual do QR | Fase 4 | base32 sem ambíguos (`O/0`, `I/1`) + dígito verificador; ~16 chars de entropia; não derivar de sequence |
| Formato da assinatura do cliente | Fase 5 | imagem PNG + hash |
| Provedor S3-compatível | Fase 3+ (fotos) | interface + MinIO em dev |
| Retenção de tombstones e de auditoria | Fase 6/7 | mecanismo pronto (`audit.purge_older_than`, `deleted_at`); definir os prazos |

---

## 9. Referências rápidas

- **Precedência de permissão** (spec §17.3): negação do usuário > permissão do
  usuário > permissão do perfil > negação padrão. Implementado em
  `permissions.Resolver.Effective`.
- **Isolamento** (ADR-0003): dois papéis PG; `WithTenantTx` seta
  `app.organization_id`/`app.user_id`/`app.device_id`/`app.request_id`; RLS
  `FORCE` em toda `app.*` tenant-scoped.
- **Auditoria** (ADR-0005): `row_history` (trigger, coluna a coluna, append-only)
  + `audit_events` (`log_event`, semântico).
- **Colunas padrão** (ADR-0006).
- **Permissões + convites** (ADR-0009); **cache + máscara** (ADR-0010).
- **Rate limit + fila + expurgo** (ADR-0011).
- Endpoints atuais: `openapi/openapi.yaml` (teste de drift em
  `cmd/auth-api/routes_test.go` — replique para o `servicelog-api`).
- Estado e dívida: `docs/progresso.md`.
- Fonte de requisitos: `servicelog-especificacao-funcional-tecnica.md`
  (§13 arquitetura, §14 multitenancy, §17 permissões, §19 sync, §21 modelo de
  dados, §22 API, §26 testes, §28 fases, §30 decisões abertas).

---

## 10. Checklist para cada entidade nova

- [ ] Migration: tabela + 7 colunas padrão + índices (`organization_id` + busca)
- [ ] Migration: `set_row_defaults` + RLS `ENABLE`/`FORCE`/policy + `audit_row_history`
- [ ] Migration de seed: chaves em `permission_catalog` + `role_template_permissions` + backfill dos perfis `is_system`
- [ ] Migration: `Down` reversível; testar `migrate down`/`up`
- [ ] `internal/db/queries/<entidade>.sql` + `sqlc generate` + commit do gerado
- [ ] `internal/<entidade>/{service.go,http.go}` no molde; toda escrita em `Authorize(...)`
- [ ] `audit.log_event('<entidade>.<acao>', ...)` nas operações sensíveis (spec §23)
- [ ] Máscara de campo onde houver campo sensível (`FilterReadable` / `UnauthorizedWrites`)
- [ ] Rota montada com `iamSvc.Authenticator`; `organization_id` nunca vem do cliente
- [ ] Tabela adicionada em `testdb.truncateSQL`
- [ ] Testes §26.1 (isolamento) e §26.2 (campo) para a entidade
- [ ] `openapi.yaml` atualizado + teste de drift passa
- [ ] `make lint` (vet + staticcheck + check-sql) e `go test -race ./...` verdes
