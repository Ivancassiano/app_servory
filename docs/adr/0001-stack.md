# ADR-0001 — Stack técnica do backend de auth

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §13, §16, §24, §30

## Contexto

A spec deixa em aberto (§30) a escolha de router HTTP, biblioteca de
queries/migrations, algoritmo do JWT e serviço de e-mail. O produto roda em uma
VPS única, é acessado apenas via API (sem SSR) e usará Postmark para e-mail
transacional.

## Decisão

| Área | Escolha | Versão inicial |
|---|---|---|
| Router HTTP | `github.com/go-chi/chi/v5` | v5.x |
| Driver PostgreSQL | `github.com/jackc/pgx/v5` (pool) | v5.x |
| Acesso a dados | `sqlc` gerando código sobre pgx; queries dinâmicas em pgx manual | v1.x |
| Migrations | `github.com/pressly/goose/v3`, SQL puro, embutidas via `embed` | v3.x |
| JWT de acesso | `github.com/golang-jwt/jwt/v5` com **EdDSA (Ed25519)** | v5.x |
| Hash de senha | Argon2id (`golang.org/x/crypto/argon2`), parâmetros versionados | — |
| Geração de IDs | UUIDv7 (`github.com/google/uuid`) | v1.6 |
| Cache | Valkey via `github.com/redis/go-redis/v9` | v9.x |
| E-mail | Postmark (produção); SMTP/Mailpit e console em dev | — |

## Alternativas consideradas

- **`net/http` puro:** viável, mas `chi` continua sendo `net/http` idiomático e
  poupa a escrita de grupos de rotas e cadeia de middleware. Custo: 1 dependência
  madura e praticamente estática.
- **ORM (`gorm`, `ent`):** rejeitado. O requisito central do produto é isolamento
  multitenant; precisamos ler o SQL exato nas revisões e testes. `sqlc` dá
  type-safety mantendo SQL explícito.
- **RSA para JWT:** só necessário se um consumidor externo exigisse RS256. Os dois
  lados (auth-api, servicelog-api) são nossos e em Go. Ed25519 gera tokens
  menores e tem menos parâmetros a errar. Ver ADR-0004.
- **`golang-migrate`:** versionamento por timestamp gera conflito de merge;
  `goose` com numeração sequencial é mais previsível.

## Consequências

- Passo de codegen (`sqlc generate`) no fluxo de build e no CI (`sqlc diff`).
- `goose` exige Go >= 1.26; o `go.mod` fixa `toolchain go1.26.x`.
- Todas as dependências têm licença permissiva (MIT/BSD/Apache-2.0), compatível
  com produto comercial. Versões e licenças registradas em `go.mod`/`go.sum`.
