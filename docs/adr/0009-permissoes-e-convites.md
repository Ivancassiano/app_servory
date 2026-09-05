# ADR-0009 — Resolução de permissões e fluxo de convite

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §5, §15.4, §17, §22.3, §26.2

## Contexto

O M4 entrega a administração de organização/usuários/perfis e o *primeiro*
mecanismo de permissões (`internal/permissions`). O motor completo (cache,
mascaramento campo a campo, testes §26.2) é o M5, mas a precedência e o formato
já ficam fixados aqui, além do fluxo de aceitação de convite.

## Decisão

### Resolução de permissões (`permissions.Resolver`)

Precedência da spec §17.3, implementada como "aplica o perfil, depois as exceções
do usuário":

```
efetivo[key] = (role_permissions.effect == 'allow')      -- perfil
efetivo[key] = (user_permission_overrides.effect=='allow')-- exceção sobrescreve
Can(key)     = efetivo[key]  (ausente => negado, spec §17.4)
```

Como no MVP há **um perfil por associação**, aplicar as exceções por último
reproduz exatamente a ordem "deny do usuário > allow do usuário > allow do
perfil > negação padrão".

- `Resolver.Effective(tx, org, user)` resolve dentro de uma transação já aberta.
- `Resolver.Authorize(tc, key, fn)` abre a transação de tenant, checa a permissão
  e só então roda `fn` na **mesma** transação — checagem e escrita atômicas, sem
  janela de corrida.
- **Sem cache** nesta fase: toda checagem lê `role_permissions` +
  `user_permission_overrides` do Postgres. O cache no Valkey
  (`org:{org}:permissions:{user}:v{permission_version}`) entra no M5.

### `permission_version`

Incrementado (`app.organization_memberships.permission_version`) sempre que:

- as permissões de um perfil mudam → **todos** os membros daquele perfil
  (`BumpPermissionVersionByRole`);
- as exceções de um usuário mudam → aquele usuário (`BumpPermissionVersionByUser`);
- o perfil de uma associação muda (`PATCH /v1/users/{id}`).

O access token carrega `permission_version`; quando o M5 ligar o cache, a
mudança de versão o invalida (spec §17.6).

### Perfis materializados por organização

Não existe "perfil global": `bootstrap` copia os templates
(`app.role_templates` → `app.roles` com `is_system = true`) para cada
organização. Perfis `is_system` podem ter permissões editadas mas não podem ser
removidos. Uma organização cria perfis adicionais via `POST /v1/roles`.

### Fluxo de aceitação de convite

`POST /v1/auth/invitations/accept` (não autenticado), corpo `{token, name?,
password, device}`:

- **A senha é sempre exigida.** E-mail novo → cria a conta com essa senha.
  E-mail já cadastrado → a senha **autentica** o usuário (equivale a um login)
  antes de adicionar a associação. Um único endpoint cobre os dois casos da
  spec §15.4.
- Token de convite guardado só como hash; uso único (`status` vai a `accepted`).
- Sucesso devolve um par de tokens (cria sessão) — o convidado já entra logado
  (spec §7.2).
- `is_default` da nova associação = true só se o usuário não tiver nenhuma outra
  associação ativa (MVP: uma organização por usuário — spec §15.3).

### Última salvaguarda de administrador

`DELETE /v1/users/{id}/membership` recusa (`LAST_ADMIN`) remover o último membro
ativo com perfil de chave `admin`. Não se pode remover a própria associação
(`SELF_REMOVAL`).

### Testes de integração paralelos

Os pacotes de teste rodam em processos paralelos sobre o **mesmo** banco
`servicelog_test`. `testdb.New` toma um `pg_advisory_lock` global numa conexão
dedicada, serializando os testes de integração entre pacotes. Substitui a ideia
de "clone de template" (Decisão C) enquanto o volume de testes for pequeno.

## Alternativas consideradas

- **Middleware `RequirePermission(key)` genérico** — faria uma transação só para
  a checagem e outra para a ação; `Authorize` com callback mantém tudo numa
  transação e um roundtrip a menos.
- **Endpoint separado para convite de usuário existente** (autenticado) — dobra a
  superfície; exigir a senha no endpoint único é mais simples e igualmente seguro.
- **Cache de permissões já no M4** — a spec pede o cache, mas sem os módulos de
  negócio consumindo permissões o ganho é nulo; fica no M5 junto dos testes §26.2.
- **`-p 1` nos testes** — serializaria tudo, inclusive os testes unitários
  rápidos; o advisory lock só serializa quem toca o banco.

## Consequências

- `internal/permissions` e `internal/organizations` são servidos pelo auth-api
  (ADR-0002); quando o `servicelog-api` existir, importam os mesmos pacotes.
- `iam` ganhou `AcceptInvitation` e um helper `establishSession` compartilhado
  com `Login`.
- Cada checagem de permissão é 1 query dupla no Postgres — aceitável no MVP;
  o M5 adiciona o cache.
- Testes de integração agora são serializados: mais lentos, porém determinísticos.
