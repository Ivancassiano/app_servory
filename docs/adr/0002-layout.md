# ADR-0002 — Layout do repositório e fronteira do auth-api

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §13.2, §29 (item 5)

## Contexto

A spec sugere um monorepo com `cmd/auth-api`, `cmd/servicelog-api`, `cmd/worker`
e módulos em `internal/` (§13.2), e determina que o Auth seja separado do
domínio "pelo menos logicamente" (§29). Esta branch entrega apenas auth,
multitenancy, RLS e permissões.

## Decisão

- Monorepo Go com módulo único `github.com/ivancassiano/auth_servory`.
- Binários: `cmd/auth-api` e `cmd/worker` nesta branch. `cmd/servicelog-api`
  será adicionado quando os módulos de negócio começarem.
- Módulos de domínio em `internal/` com fronteiras explícitas:
  `iam`, `organizations`, `permissions`, `audit`, e `platform/*` para
  infraestrutura transversal.
- **No MVP, `auth-api` também expõe a administração de organização, usuários e
  perfis** (`/v1/organization`, `/v1/users`, `/v1/roles`,
  `/v1/users/{id}/permission-overrides`), além de `/v1/auth/*` e `/v1/me`.

## Alternativas consideradas

- **Criar já um `admin-api` ou `servicelog-api` separado para org/usuários:**
  adiciona um binário e um pipeline de deploy sem necessidade agora. A separação
  lógica em pacotes `internal/` já permite mover esses handlers depois sem
  reescrever a lógica.
- **Multi-módulo Go (um go.mod por serviço):** peso de gerência desproporcional
  para o MVP; a spec pede explicitamente para não inflar a arquitetura (§13.2).

## Consequências

- Sem gerência de usuário/perfil não há como testar permissões — manter isso no
  auth-api destrava o M4/M5 desta branch.
- Quando o `servicelog-api` surgir, os pacotes `organizations` e `permissions`
  serão importados por ambos os binários; o motor de permissões (`internal/permissions`)
  já é desenhado como biblioteca reutilizável, não acoplado ao HTTP do auth-api.
- O `worker` compartilha `platform/*` e o pacote `mail`.
