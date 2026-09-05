# ADR-0020 — Auditoria e correção do backfill de permissão quebrado

- **Status:** aceito
- **Data:** 2026-09-05
- **Contexto:** dívida técnica registrada em ADR-0017/ADR-0031 ("bug
  sistêmico" descoberto ao ligar modelos de etiqueta)

## Contexto

ADR-0017 descobriu que o padrão de backfill usado desde a migration 00010
(dar uma permissão nova aos perfis `is_system` já materializados de
organizações existentes) roda como `servory_owner` **sem contexto de
tenant** — `app.current_org()` é `NULL` fora de uma sessão de aplicação —
e `app.roles`/`app.role_permissions`/`app.organization_memberships` têm
`FORCE ROW LEVEL SECURITY` (aplica a policy mesmo ao dono da tabela). O
`INSERT`/`UPDATE` do backfill roda sem erro, mas a policy
`organization_id = app.current_org()` não bate com nenhuma linha — afeta
**0 linhas** para toda organização criada antes da migration rodar. Só
organizações criadas depois, via `organizations.Bootstrap` (contexto de
tenant de verdade), ganham a permissão nova corretamente desde o início.
ADR-0031 corrigiu isso só para `label_template` (00030) e registrou como
dívida as demais: **00010** (equipment_type), **00012**
(service_order_type), **00015** (company), **00016**
(service_order_part), **00022** (service_order.pdf) — todas com o mesmo
padrão exato de `INSERT INTO app.role_permissions ... FROM app.roles r` +
`UPDATE app.organization_memberships SET permission_version = ...`.

## Levantamento

Antes de corrigir, medido no banco de dev (22 organizações, 63 perfis
`is_system`) quantas linhas de `role_permissions` esperadas (por
`role_template_permissions`) realmente faltavam, por prefixo de chave:

| prefixo               | faltando | esperado |
|-----------------------|---------:|---------:|
| `service_order`       |       57 |      252 |
| `service_order_part`  |       12 |      252 |
| `equipment_type`, `company`, `service_order_type`, `label_template`, ... | 0 | — |

Só `service_order.pdf` (57, de 00022) e `service_order_part.*` (12, de
00016) tinham lacuna real neste banco — nenhuma das 22 organizações atuais
é anterior a 00010/00012/00015 (foram todas criadas depois, via
`organizations.Bootstrap`, então já nasceram com essas permissões
corretas). `permission_version` também expôs o mesmo bug de um ângulo
diferente: das 7 migrations que tentam bumpar (`00010/00012/00015/00016/
00022/00030/00031`), só **uma** (`00031`, a que já tinha o fix) conseguiu —
24 das 25 organizations estavam em `permission_version = 2` (um só bump
bem-sucedido), quando deveriam refletir bem mais mudanças de catálogo ao
longo do tempo.

## Decisão

Uma migration nova (`00034`) reaplica o mesmo `INSERT ... ON CONFLICT DO
NOTHING` de backfill das cinco migrations, dentro de uma janela `NO FORCE
ROW LEVEL SECURITY` (mesma técnica de 00031), para os cinco prefixos —
inclusive os três que já mostravam zero linhas faltando neste banco: não
há garantia de que um ambiente novo, ou um reset de dados, preserve a
mesma ordem de criação de organizações que fez esses três "por acaso" não
terem lacuna aqui — é o mesmo bug, corrigido de uma vez por todas em vez
de corrigir só o que dói agora. Um único bump de `permission_version` ao
final basta para invalidar qualquer cache de permissão efetiva que um
cliente já tivesse — o contador só precisa mudar, não precisa repetir uma
vez por migration histórica.

Reaplicar os `INSERT`s originais (em vez de escrever uma correção
"genérica" que varresse `role_template_permissions` inteiro) mantém cada
bloco rastreável à migration que ele corrige — quem for auditar de novo no
futuro lê os comentários e sabe exatamente qual dívida cada bloco fecha.

## Consequências

- `migrations/00034_permission_backfill_audit_fix.sql`: sem mudança de
  schema, só dados — reaplica os cinco backfills + um bump de
  `permission_version`.
- Verificado ao vivo (banco de dev, antes/depois): as 69 linhas que
  faltavam (`service_order.pdf` + `service_order_part.*`) foram
  preenchidas; todas as 25 organizations tiveram `permission_version`
  incrementado.
- Fecha a dívida técnica registrada em ADR-0017/ADR-0031 — nenhuma
  migration de backfill de permissão conhecida continua quebrada.
- Não é uma correção estrutural do padrão em si (uma migration nova que
  repita esse erro no futuro sofreria o mesmo bug) — isso ficaria para uma
  mudança maior (ex.: um helper de migration que sempre desliga/religa
  `FORCE ROW LEVEL SECURITY` ao redor de qualquer backfill, ou rodar
  backfills fora de migration, por um comando de aplicação sob tenant de
  verdade). Fora do escopo desta auditoria pontual.
