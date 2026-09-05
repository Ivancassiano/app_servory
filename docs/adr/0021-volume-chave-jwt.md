# ADR-0021 — Volume de chave JWT separado (só pública) para servicelog-api/worker

- **Status:** aceito
- **Data:** 2026-09-05
- **Contexto:** item de hardening deixado aberto pelo ADR-0015

## Contexto

ADR-0015 trocou `servory_app` (compartilhado) por dois papéis de banco de
menor privilégio (`servory_business`/`servory_worker`), mas registrou uma
lacuna equivalente no nível do container: o volume `jwtkeys` monta
`/secrets/jwt` — que contém `<kid>.pem` (chave **privada**, o auth-api
assina) e `<kid>.pub.pem` (chave pública, todos verificam) — inteiro em
`auth-api`, `servicelog-api` **e** `worker`. `tokens.LoadVerifyKeySet`
(usado por `servicelog-api`) já só lê `*.pub.pem` — a aplicação nunca toca
na privada — mas isso é uma garantia de **código**, não de **container**:
um `servicelog-api` comprometido (RCE, leitura arbitrária de arquivo, etc.)
conseguiria ler `k1.pem` do disco mesmo assim, porque o volume está montado
ali. Auditando o `worker`, ele nem chama `tokens.LoadKeySet`/
`LoadVerifyKeySet` em lugar nenhum — não verifica nem assina token algum
(só expõe um healthcheck HTTP) — o volume/env ali era vestígio de
copy-paste do molde de `servicelog-api`, sem uso real.

## Decisão

### Volume novo, só com `*.pub.pem`, para quem só verifica

`docker-compose.prod.yml` ganha `jwtkeys-pub` (volume novo, separado de
`jwtkeys`): `keygen` grava a chave nos dois lugares — a privada+pública em
`jwtkeys` como sempre, e uma cópia só da pública em `jwtkeys-pub` — via um
`TOKEN_PUBLIC_KEY_DIR` novo (opcional) que `keygenCmd`
(`cmd/auth-api/commands.go`) usa para copiar o arquivo `.pub.pem` depois de
gerar/confirmar o par. `servicelog-api` passa a montar `jwtkeys-pub:
/secrets/jwt:ro` (mesmo caminho dentro do container, `TOKEN_KEY_DIR` não
muda) — nunca mais tem acesso de filesystem à chave privada, mesmo que o
código nunca a lesse. `auth-api` continua com `jwtkeys` (precisa assinar).
Mesma mudança no `docker-compose.yml` de dev (`../secrets/jwt-pub`, gerado
por `make keys` via o `TOKEN_PUBLIC_KEY_DIR` do `.env`).

### `worker` não monta chave JWT nenhuma

Confirmado por grep que nada em `cmd/worker` chama `tokens.LoadKeySet`/
`LoadVerifyKeySet` — o volume e o `TOKEN_KEY_DIR`/`TOKEN_ACTIVE_KID` que
ele tinha eram cópia do molde de `servicelog-api` sem função real. Menor
privilégio de verdade aqui não é "só a pública" — é **nenhuma**: removido
o volume e as duas env vars do serviço `worker` em dev e prod.

## Consequências

- `internal/platform/tokens`: sem mudança de API — a cópia do `.pub.pem`
  é feita por um helper novo (`syncPublicKey`) só em
  `cmd/auth-api/commands.go`, não no pacote `tokens` (é puramente uma
  cópia de arquivo, não uma operação de chave).
- `cmd/auth-api/commands.go`: `keygenCmd` aceita `TOKEN_PUBLIC_KEY_DIR`
  (opcional; vazio = comportamento antigo, sem cópia) — idempotente:
  rodar de novo com a chave já existente ainda sincroniza a cópia pública
  se `TOKEN_PUBLIC_KEY_DIR` estiver setado e a cópia não existir lá.
- `deploy/docker-compose.prod.yml`: volume `jwtkeys-pub` novo; `keygen`
  grava nos dois; `servicelog-api` monta só o novo (`:ro`); `worker` sem
  volume/env de chave nenhum.
- `deploy/docker-compose.yml` (dev): mesma mudança via bind mount
  (`../secrets/jwt-pub`); `Makefile`/`.env.example` documentam
  `TOKEN_PUBLIC_KEY_DIR`.
- Verificado ao vivo: `make keys` (idempotente, chave `dev` já existia)
  copiou `dev.pub.pem` para `./secrets/jwt-pub/`; stack local subiu com
  `auth-api` assinando e `servicelog-api` verificando token através do
  volume só-público.
- Fecha o último item de hardening pendente do ADR-0015.
