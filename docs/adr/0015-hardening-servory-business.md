# ADR-0015 — Papéis `servory_business`/`servory_worker`: menor privilégio fora do auth-api

- **Status:** aceito
- **Data:** 2026-09-04
- **Contexto da spec:** §14.3 (papéis de banco), §25 (confiabilidade/segurança)

## Contexto

Hoje `auth-api`, `servicelog-api` e `worker` conectam ao Postgres com o mesmo
papel, `servory_app` — que tem `SELECT/INSERT/UPDATE/DELETE` em **todo**
schema `iam` (usuários, hash de senha, sessões, refresh tokens, tokens de
reset de senha, convites, dispositivos) além de `app`/`audit`. Só o
`auth-api` emite e gira credenciais de verdade; `servicelog-api` e `worker`
nunca deveriam precisar tocar `iam.refresh_tokens` ou
`iam.password_reset_tokens` — mas hoje conseguiriam, porque o papel de banco
não distingue.

Isso já estava anotado como dívida técnica desde a Fase 1
(`docs/progresso.md`, "Futuro (quando o servicelog-api for separado)") e
como comentário em `deploy/docker-compose.prod.yml`.

## Decisão

### Dois papéis novos, escopo por *allowlist* explícita — não por exclusão

Comecei desenhando **um** papel compartilhado (`servory_business`) para
`servicelog-api` e `worker`, já que os dois atendem o mesmo domínio de
negócio. Ao mapear tabela por tabela apareceu uma divergência real: o
`worker` **processa** a fila de e-mail (`internal/mailq.Dispatcher` —
`SELECT` pra reivindicar pendentes, `UPDATE` pra marcar enviado/falho,
`DELETE` pra expurgar enviados antigos), enquanto o `servicelog-api` só
**enfileira** convite (`INSERT`). Se os dois usassem o mesmo papel, o
`servicelog-api` ganharia `SELECT` na fila só por compartilhar o papel do
`worker` — e essa fila carrega, entre outras coisas, o **link de redefinição
de senha** que o `auth-api` enfileira (corpo do e-mail em texto puro, com o
token). Não valia a pena abrir essa janela só para simplificar o
provisionamento. Dois papéis, então:

`servory_business` (`servicelog-api`) e `servory_worker` (`worker`) — mesma
base de `servory_app`: `NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS`, RLS
continua sendo barreira real para os dois.

**`servory_business`** recebe:

- **`app.*` e `audit.*` — acesso igual ao de hoje** (é o domínio de negócio
  inteiro do `servicelog-api`, nada muda aqui).
- **`iam.*` — só as tabelas que o código do `servicelog-api` realmente toca**
  (`internal/organizations`, `internal/permissions`, `internal/people`,
  `internal/audit` só rodam nesse processo; `internal/iam` é compartilhado
  com o `auth-api`, mas só `Authenticator` e `GET /v1/me` são montados aqui):

  | tabela | privilégio | por quê |
  |---|---|---|
  | `iam.users` | `SELECT` | `GET /v1/me`, verificação de token, convites |
  | `iam.people` | `SELECT, INSERT, UPDATE` | `GET/PATCH /v1/me/person` |
  | `iam.invitations` | `SELECT, INSERT, UPDATE` | convites de usuário |
  | `iam.sessions` | `SELECT` | checar revogação (fallback do Valkey) |
  | `iam.email_outbox` | `INSERT` | só enfileirar convite — nunca ler o que está na fila |

**`servory_worker`** recebe:

- **`app.*` e `audit.*` — acesso igual ao de hoje** (o worker gera PDF do
  laudo, `internal/pdfjobs`, e roda o expurgo de auditoria).
- **`iam.email_outbox`** — `SELECT, UPDATE, DELETE` (reivindicar, marcar
  resultado, expurgar enviados — `internal/mailq.Dispatcher`); sem `INSERT`,
  o worker nunca enfileira, só processa.
- Nenhuma outra tabela de `iam` — o worker não lida com sessão, pessoa,
  convite ou usuário diretamente.
- `audit.purge_older_than` já é executável por qualquer papel (Postgres
  concede `EXECUTE` a `PUBLIC` por padrão em funções, e a migration original,
  ADR-0011, nunca revogou isso) — nenhum grant novo necessário aqui.

Os dois deliberadamente **sem** `ALTER DEFAULT PRIVILEGES` no schema `iam` —
uma tabela `iam` nova não fica acessível por padrão para nenhum dos dois; é
preciso uma decisão explícita (linha nova na migration), não uma concessão
automática. `app`/`audit` continuam com `ALTER DEFAULT PRIVILEGES` para
ambos (mesmo padrão do `servory_app`), porque ali os dois são donos de
verdade do próprio domínio.

**Nunca concedido a nenhum dos dois:** `iam.refresh_tokens`,
`iam.password_reset_tokens`, `iam.devices` — só o `auth-api` os toca (login,
refresh, esqueci-senha, listagem de sessões/dispositivos).

### `password_hash` nunca trafega para servory_business, nem por acidente

Não bastava restringir por tabela: `iam.users` continua precisando de
`SELECT` (para `/v1/me`, convites), e a convenção do projeto é `SELECT *`
(sqlc). Auditei os dois pontos que liam `iam.users` a partir de código que
roda no `servicelog-api` (`GetUserByID`, usado por `Me()`; e
`GetUserByNormalizedEmail`, usado por convites) e confirmei que **nenhum dos
dois lê `.PasswordHash`** — só `login.go`/`password.go`/`acceptinvite.go`
leem (e esses só rodam no `auth-api`, com `servory_app`, acesso completo).

Em vez de confiar só nisso (o código de hoje não usar a coluna não impede um
`SELECT *` de trazê-la para dentro do processo), troquei essas duas queries
por versões com lista de colunas explícita, **sem** `password_hash`:
`GetUserByID` (a query em si, usada nos dois processos) e uma nova
`GetUserProfileByNormalizedEmail` (só para o caminho de convite; login/reset/
aceitar-convite continuam com a `GetUserByNormalizedEmail` original, que
precisa do hash). Assim, mesmo que uma injeção de SQL ou um bug futuro
tentasse ler `password_hash` a partir de código que roda no
`servicelog-api`, a query não devolveria a coluna — não é preciso confiar em
disciplina de code review para manter essa garantia.

### Volume de chaves JWT: só a pública para servicelog-api/worker

Comentário já existia em `docker-compose.prod.yml`. O volume `jwtkeys`
guarda `*.pem` (privada) e `*.pub.pem` (pública) juntos, montado (mesmo que
somente-leitura) em todos os serviços — inclusive `servicelog-api`/`worker`,
que só chamam `tokens.LoadVerifyKeySet` (só as `.pub.pem`). Nesta entrega
**não separei os volumes** — fica registrado como item ainda aberto (ver
"Fora do escopo").

## Alternativas consideradas

- **Coluna restrita via `REVOKE SELECT (password_hash)`** em vez de reescrever
  as queries — Postgres suporta privilégio por coluna, mas isso quebraria
  `SELECT *` em qualquer query que ainda precisasse ler a linha inteira sem
  querer o hash, forçando o mesmo trabalho de reescrever queries mesmo assim.
  Reescrever a query já resolve e fica explícito no próprio SQL.
- **Um único papel compartilhado** (`servory_business` para
  `servicelog-api` **e** `worker`) — foi o desenho inicial, descartado ao
  mapear `iam.email_outbox`: o `worker` precisa `SELECT` para processar a
  fila, o que incluiria o link de redefinição de senha que o `auth-api`
  enfileira; compartilhar o papel deixaria o `servicelog-api` ler esse
  conteúdo só por rodar sob o mesmo papel do `worker`, sem nenhuma
  necessidade real. Dois papéis, com o `iam.email_outbox` como a única
  divergência de privilégio hoje, fecha essa janela sem custo real de
  provisionamento (mesma migration, mais um `CREATE ROLE`).
- **Não mexer, aceitar o risco** — rejeitada: o custo de implementar é baixo
  (uma migration + trocar `POSTGRES_DSN` de dois serviços) frente ao ganho
  real de conter o estrago de um `servicelog-api` comprometido.

## Consequências

- `deploy/postgres/initdb/00-roles.sh` cria os dois papéis (cluster-level,
  uma vez); migrations concedem os privilégios (database-level, versionado,
  reversível) — `00026` para `servory_business`, `00027` para
  `servory_worker`.
- `scripts/db.sh` passa a conceder `CONNECT` também a `servory_business` e
  `servory_worker` em todo banco novo (dev/test).
- `servicelog-api` passa a usar `POSTGRES_DSN` com `servory_business` e
  `worker` com `servory_worker`, ambos em vez de `servory_app`
  (`docker-compose.yml`, `docker-compose.prod.yml`); `auth-api` fica com
  `servory_app`, sem mudança.
- **Fora do escopo desta entrega** (registrado para não reabrir a decisão à
  toa): separar o volume de chaves JWT (só `.pub.pem` para
  `servicelog-api`/`worker`) — mecânico, mas exige mexer no `Dockerfile`/
  `keygen` para escrever em dois destinos.
