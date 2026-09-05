# ADR-0011 — Rate limiting, fila de e-mail, expurgo de auditoria e drift do OpenAPI

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §13.1, §22, §23, §24, §30

## Contexto

O M6 fecha a fundação de segurança (Fases 0–1): endurecimento de rate limiting,
tira o envio de e-mail do caminho do handler, dá consulta e retenção de
auditoria e alinha o OpenAPI ao código.

## Decisão

### Rate limiting por IP (`httpx.RateLimitByIP`)

- Janela fixa por IP via `INCR` no Valkey: chave `rate:ip:{hash(ip)}:{bucket}`,
  onde `bucket = unix / window_seconds`. Sem sub-chave por rota — é um teto
  global do `/v1` por IP, complementando o limite por e-mail do login.
- `RATE_LIMIT_PER_IP` (default 120) / `RATE_LIMIT_WINDOW` (default 1m).
- 429 com `Retry-After`. Sem Valkey ou em erro do backend → deixa passar
  (degrada, spec §20).
- Aplicado em `mountRoutes` só quando `deps.Valkey != nil` (evita a armadilha do
  typed-nil na interface `Limiter`).

### Fila de e-mail (`internal/mailq`, migration 00007)

- `iam.email_outbox` — sem RLS (infra, processada globalmente) e **sem trigger de
  auditoria** (o corpo carrega tokens de uso único).
- `MAIL_ASYNC=true`: o `mail.Sender` injetado nos serviços é o `mailq.Enqueuer`
  (grava uma linha). O `worker` roda o `mailq.Dispatcher`: `ClaimDueEmails`
  (`FOR UPDATE SKIP LOCKED`) → envia pelo transporte real → `MarkEmailSent` /
  `MarkEmailAttemptFailed` (backoff exponencial, `maxAttempts=6`, depois
  `status='failed'`).
- `MAIL_ASYNC=false` (default): comportamento anterior (envio síncrono).
- Ganho: tira a latência e o **side-channel de timing** do `password/forgot` do
  caminho do handler (spec §24), e falha de SMTP não afeta a resposta.

### Expurgo de auditoria (`audit.purge_older_than`)

- A barreira append-only (ADR-0005) abre uma exceção **só** quando o GUC
  `audit.allow_purge = 'on'` está setado na transação. Apenas a função
  `audit.purge_older_than(interval)` o define, via `SET LOCAL`.
- A função é `SECURITY DEFINER` (roda como `servory_owner`, que tem `DELETE` em
  `audit.*`); `servory_app` só recebe `EXECUTE`. `search_path` fixo.
- O `worker` chama a função a cada 6 h quando `AUDIT_RETENTION > 0` (default 0 =
  manter para sempre). Decisão de política de retenção fica com a operação
  (spec §30); o mecanismo está pronto.

### Consulta de auditoria (`internal/audit`)

- `GET /v1/audit` — eventos semânticos da organização do ator, ordem decrescente,
  paginação keyset por `(occurred_at, id)` em cursor base64. Permissão `audit.read`.
- `GET /v1/audit/row-history?schema=&table=&row_id=` — história coluna a coluna de
  uma linha; filtra por `organization_id` no código (row_history não tem RLS).
- `audit_events`/`row_history` não têm RLS; o serviço filtra por
  `organization_id` explicitamente, dentro de `Authorize`.

### OpenAPI + teste de drift

- `openapi/openapi.yaml` reescrito com todos os endpoints de M3–M6.
- `cmd/auth-api/routes_test.go`: monta o router real (`buildDependencies` +
  `mountRoutes`), enumera as rotas com `chi.Walk` e compara com as operações do
  YAML — falha nos dois sentidos (documentado sem implementar / implementado sem
  documentar). Exige `TEST_POSTGRES_*`.

### Itens de dívida fechados junto

- `GET /v1/me` recusa (`USER_INACTIVE`) se a associação foi removida/suspensa
  depois da emissão do token.
- `valkey.Connect` com `MaxRetries: -1` — falha rápido e silenciosa no modo
  degradado.

## Alternativas consideradas

- **Rate limit por rota** — mais preciso, porém mais chaves e sintonia; o teto
  global por IP + o limite por e-mail do login cobrem os abusos relevantes no MVP.
- **Fila de e-mail no Valkey** (lista) — perderia durabilidade se o Valkey caísse
  (spec §20 exige que a queda do Valkey não cause perda). Tabela no Postgres é a
  fonte de verdade.
- **`pgaudit` / expurgo por particionamento** — melhor em escala; particionar
  `row_history` por mês entra no hardening real (Fase 7) se o volume exigir.
- **Validador OpenAPI completo (`kin-openapi`)** — dependência pesada para um
  ganho marginal sobre o teste de drift baseado em `chi.Walk`.

## Consequências

- Novo binário de trabalho real no `worker`; o compose liga `MAIL_ASYNC=true` e o
  `worker` passa a depender de Postgres + migrate.
- `audit.purge_older_than` é a **única** porta de saída de linhas de `audit.*`;
  qualquer outro `DELETE` continua barrado.
- O teste de drift do OpenAPI quebra de propósito quando um endpoint é
  adicionado/removido sem atualizar o YAML.
- Fim da Fase 1: a branch `feature/auth-foundation` pode ser mergeada; os módulos
  de negócio começam em nova branch com `cmd/servicelog-api`.
