# ADR-0010 — Cache de permissões, mascaramento de campo e degradação do Valkey

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §7.1, §17.4, §17.6, §20, §26.2

## Contexto

O M5 fecha o motor de permissões iniciado no M4 (ADR-0009): cache no Valkey,
mascaramento campo a campo e exposição das permissões para o cliente. Também
corrige o item de hardening "startup tolerante ao Valkey".

## Decisão

### Cache no Valkey, chaveado pela versão do banco

`org:{org}:permissions:{user}:v{permission_version}` guarda o **conjunto de
permissões concedidas** (JSON `["chave", ...]`).

- O `permission_version` da chave é lido de `app.organization_memberships` **no
  momento da resolução**, não do claim do access token. Assim um bump de versão
  (edição de perfil/exceção) invalida imediatamente para todos, mesmo quem ainda
  carrega um token antigo — não há janela de permissão obsoleta.
- Cada resolução faz 1 query (`GetMembership`) sempre; no hit, evita as 2 queries
  de `role_permissions` + `overrides`. No miss, recomputa e grava (`TTL 1h`, só
  rede de segurança para chaves órfãs).
- Sem Valkey (`Resolver.cache == nil`): resolve sempre do Postgres. Sem
  invalidação explícita — a chave nova por versão já basta; chaves velhas expiram.
- O access token continua carregando `permission_version` como **dica** (para o
  cliente e para observabilidade), não como fonte de autorização.

### Mascaramento campo a campo (`Effective`)

Chave de campo no catálogo: `{resource}.{field}.{read|write}`. Como
`app.role_permissions.permission_key` tem FK para `app.permission_catalog`, um
campo fora do catálogo nunca é concedido → **"campo novo inicia negado" sai de
graça** (spec §17.4).

- `CanReadField` / `CanWriteField(resource, field)`.
- `FilterReadable(resource, payload, fields)` — remove do map de saída as chaves
  sem `.read`.
- `UnauthorizedWrites(resource, payload, fields)` — devolve as chaves de entrada
  sem `.write` (o handler rejeita a requisição inteira).
- `fields` mapeia chave-JSON → nome-de-campo-no-catálogo; o chamador (módulo de
  negócio, M+) declara esse mapa. Sem entidades de negócio ainda, o M5 só entrega
  e testa o mecanismo.

### `GET /v1/me/permissions`

Servido pelo pacote `permissions` (não pelo `iam`, para não criar ciclo
`iam` ↔ `permissions`). Devolve `{permissions: [...], permission_version}`.
Cobre "sincronizar permissões" do fluxo de login (spec §7.1) e permite ao cliente
Flutter ocultar controles (spec §17.4, §26.2). Não exige permissão — o usuário
sempre vê as suas.

### Startup tolerante ao Valkey (spec §20)

`valkey.Connect` faz o ping com timeout de 3 s e `DialTimeout` de 2 s.
`buildDependencies` captura a falha, loga um WARN e segue com `cache = nil`.
`/readyz` só lista o Valkey como dependência quando ele subiu; `/healthz`
continua 200. Consumidores (`iam`, `Resolver`) são nil-safe.

### Outros itens de hardening entregues no M5

- `httpx.LimitBody` (1 MiB) + `middleware.Timeout(20s)` na pilha base;
  `http.Server` com `ReadTimeout`/`WriteTimeout`/`IdleTimeout`.
- `mail`: `headerSafe` remove CR/LF de `From`/`To`/`Subject`.
- `/readyz` não expõe mais `err.Error()` das dependências (só loga o detalhe).

## Alternativas consideradas

- **Chave por `permission_version` do token** — evitaria a query `GetMembership`,
  mas deixaria uma janela de até 10 min com permissões obsoletas após uma edição.
  A query extra é barata e a correção vale mais.
- **Invalidação explícita** (deletar as chaves ao editar) — para bump por perfil
  seriam N deletes (um por membro); a chave-por-versão torna isso desnecessário.
- **Fold das permissões no `GET /v1/me`** — exigiria mover `iam.Principal` para um
  pacote neutro (refatoração ampla). Endpoint separado agora; consolidar depois.
- **Cachear o mapa completo `{chave: bool}`** — só as concedidas importam para
  `Can`; guardar a lista é menor e mais simples.

## Consequências

- Toda checagem de permissão custa ≥ 1 query (membership) + cache; no miss, 3
  queries. Aceitável no MVP.
- `Resolver` agora depende de `internal/platform/valkey` (opcional).
- O contrato de `fields` para mascaramento fica com os módulos de negócio; quando
  eles chegarem, cada endpoint declara seu mapa e chama `FilterReadable` /
  `UnauthorizedWrites`.
- Testes §26.2 cobertos em `internal/permissions/permissions_test.go`
  (mascaramento de leitura/escrita, campo novo negado, edição invalida cache,
  negação do usuário prevalece, leitura vem do cache).
