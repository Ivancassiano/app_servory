# ADR-0008 — Fluxo de sessão: rotação de refresh, revogação e cache

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §7.1, §15.3, §16.2, §16.4, §20, §26.3

## Contexto

O M3 liga os primitivos do M2 (ADR-0007) aos casos de uso: login, refresh,
logout e recuperação de senha (`internal/iam`). Alguns pontos operacionais não
estavam fixados.

## Decisão

### Organização ativa no login (spec §15.3)

`iam.pickMembership`: 1 associação ativa → usa; várias → usa a marcada
`is_default`; várias sem padrão → erro `ORGANIZATION_NOT_RESOLVED` (409). O
cliente **não** escolhe a organização.

### Dispositivo

O cliente pode enviar `device.id` (UUID que ele mesmo gera, inclusive offline —
spec §19.1). É reaproveitado só se já existir **e pertencer ao usuário**; caso
contrário o servidor gera um novo id. Nunca se transfere um `iam.devices` de um
usuário para outro.

### Rotação de refresh e detecção de reuso (spec §16.2)

- Cada `POST /v1/auth/refresh` marca o token atual (`used_at`) e cria o próximo
  na mesma `family_id`, com `parent_id` encadeado.
- Expiração do novo token: `min(now + REFRESH_TOKEN_TTL, session.expires_at)` —
  o limite absoluto da sessão (90 dias) sempre vence.
- **Reuso** = um token com `used_at` ou `revoked_at` reaparece. Resposta:
  `RevokeRefreshTokenFamily` **e** revogação da própria sessão + evento
  `auth.refresh_reuse`. Revogar só a família deixaria o atacante e a vítima
  brigando pela cadeia; matar a sessão encerra os dois.

### Access token e claims

Claims: `iss, sub, sid, did, org, aud, iat, nbf, exp, permission_version`
(ADR-0007 + `did` para a auditoria montar o `TenantContext`). Sem matriz de
permissões, sem `token_version` (a revogação é por sessão).

### Revogação e cache (spec §16.4, §20)

- Fonte de verdade: `iam.sessions.revoked_at` no Postgres.
- Ao revogar (logout, logout-all, reuso, reset de senha, `DELETE /sessions/{id}`)
  grava-se `session:revoked:{sid}` no Valkey com TTL
  `ACCESS_TOKEN_TTL + REVOKED_SESSION_GRACE`.
- O middleware `Authenticator` checa o Valkey; se o Valkey falhar, cai para
  `SELECT` em `iam.sessions` (degrada desempenho, não integridade — spec §20).
- Reset de senha revoga todas as sessões e incrementa `token_version` (belt-and-
  suspenders para o servicelog-api no M5).

### Rate limiting (spec §24)

Contadores no Valkey: login `10 / 15 min` por `email+hash(IP)`; forgot
`5 / 1 h`. Sem Valkey o rate limit é ignorado (não bloqueia login). Endurecimento
(bloqueio progressivo, captcha) fica para o M6.

### E-mail

Envio **síncrono** no handler (`internal/platform/mail`: console/smtp/postmark).
Mover para o `worker` é evolução posterior (spec §13.1); falha de envio não
derruba o fluxo de `forgot` (log + resposta 202).

### Enumeração de conta

`login` e `password/forgot` devolvem sempre resposta genérica; o `login` roda um
Argon2id "de mentira" quando o e-mail não existe para equalizar o tempo.

## Alternativas consideradas

- **`token_version` nas claims + checagem por request** — exige leitura do
  usuário a cada request no servicelog-api; a revogação por sessão + cache cobre
  os casos da spec com custo menor.
- **Refresh sem detecção de reuso** — a spec §16.2 exige explicitamente.
- **Sliding window na sessão** (estender `expires_at` a cada refresh) — contraria
  o "limite absoluto de sessão" (§16.2).

## Consequências

- Todo endpoint autenticado tem o `Principal` no contexto; handlers de negócio
  (M4+) abrem `WithTenantTx(principal.TenantContext(requestID))`.
- `internal/iam` depende de Postgres + (opcionalmente) Valkey; testado em
  `internal/iam/iam_test.go` contra os dois (Valkey opcional).
- Assinatura de `tokens.Claims` mudou (novo campo `DeviceID`) — consumidores
  recompilam.
