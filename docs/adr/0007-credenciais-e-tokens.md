# ADR-0007 — Parâmetros de senha e formato dos tokens

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §16, §24, §26.3, §30 (itens "Ed25519 ou RSA", "duração dos tokens")

## Contexto

O M2 implementa os primitivos de credencial e token que o M3 (login/refresh)
vai consumir. A spec exige Argon2id com parâmetros versionados (§24), access
token JWT curto com assinatura assimétrica (§16.1) e refresh token opaco
guardado só como hash (§16.2). Faltava fixar valores e formato.

## Decisão

### Senha — Argon2id (`internal/platform/passwords`)

Perfil padrão (`passwords.Default`):

| parâmetro | valor |
|---|---|
| memória | 64 MiB |
| iterações (t) | 3 |
| paralelismo (p) | 4 |
| salt | 16 bytes (CSPRNG) |
| chave | 32 bytes |

- Serialização **PHC**: `$argon2id$v=19$m=65536,t=3,p=4$<salt b64>$<hash b64>`.
  O hash carrega os próprios parâmetros — um hash antigo continua verificável
  depois de o perfil mudar.
- `NeedsRehash` compara os parâmetros do encoded com `passwords.Default`; o M3
  reescreve o hash no próximo login bem-sucedido quando diferirem.
- Parâmetros são constantes de código (versionadas por este ADR), não config de
  ambiente: mudança de custo é decisão revisada, não tuning solto.
- Comparação em constant time (`subtle.ConstantTimeCompare`).

### Access token — JWT EdDSA (`internal/platform/tokens`)

- Biblioteca: `github.com/golang-jwt/jwt/v5` (já no módulo, madura, mantida).
- Algoritmo: **EdDSA/Ed25519** (ADR-0004). `WithValidMethods(["EdDSA"])` barra
  troca de algoritmo; `WithStrictDecoding()` barra base64 maleável.
- Header traz `kid`; a verificação resolve a chave pública pelo `kid` no
  `KeySet`, permitindo rotação sem downtime.
- Claims (spec §16.1): `iss`, `sub` (user), `sid` (sessão), `org` (organização
  ativa), `aud`, `iat`, `nbf`, `exp`, `permission_version`. **Sem** matriz de
  permissões.
- Validação obrigatória: método, emissor, audiência, expiração (`WithExpirationRequired`),
  `nbf`. Relógio injetável (`clock.Clock`) para testes.
- TTL vem de `config.AccessTokenTTL` (default 10 min, spec §16.1).

### Refresh token — opaco (`internal/platform/tokens`)

- 256 bits de CSPRNG, `base64url` sem padding (`NewOpaque`).
- Armazenado **apenas** como `SHA-256` hex (`HashOpaque`). SHA-256 (não Argon2)
  é adequado: o segredo tem entropia total, não há espaço de busca a encarecer.
- Comparação por hash em constant time (`EqualHash`).
- Rotação, detecção de reuso e revogação de família: M3, sobre `iam.refresh_tokens`
  (`family_id`/`parent_id` já existem — migration 00002).

## Alternativas consideradas

- **bcrypt / scrypt** para senha — Argon2id é a recomendação atual (OWASP) e a
  spec já pede explicitamente.
- **JWT artesanal** — evitar dependência não compensa o risco de erro em parsing
  de JWT; `golang-jwt` já está no grafo do módulo.
- **PASETO** no lugar de JWT — a spec fixa JWT (§16.1); PASETO não traz ganho
  suficiente para divergir.
- **Refresh token como JWT** — precisaria de blocklist para revogar; opaco +
  linha no Postgres é a fonte de verdade (spec §16.2/§16.4).
- **Parâmetros de Argon2 em env** — abre porta para produção rodar com custo
  fraco por engano; constante revisável é mais segura.

## Consequências

- 64 MiB por hash de senha: em rajada de logins concorrentes o pico de memória
  é `64 MiB × logins simultâneos`. Aceitável no MVP (VPS única, volume baixo);
  reavaliar com `p`/`m` menores se virar gargalo — nova revisão deste ADR.
- Trocar o perfil não invalida sessões; só força rehash gradual no login.
- Rotação de chave JWT: basta adicionar o novo `<kid>.pem` ao `TOKEN_KEY_DIR` e
  apontar `TOKEN_ACTIVE_KID`; tokens do kid anterior seguem válidos até expirar.
- Testes (§26.3): cobertos em `passwords_test.go` e `tokens/access_test.go`
  (expirado, audiência/emissor errados, assinatura adulterada, kid desconhecido,
  rotação).
