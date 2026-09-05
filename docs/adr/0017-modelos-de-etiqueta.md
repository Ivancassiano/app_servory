# ADR-0017 — Modelos de etiqueta (texto congelado, selecionado na impressão)

- **Status:** aceito
- **Data:** 2026-09-04
- **Contexto da spec:** §10.3 (texto padrão, limite de linhas/caracteres)

## Contexto

ADR-0016 implementou o PDF físico da etiqueta com um bloco de identificação
da empresa resolvido "ao vivo" a partir de `company_id` no momento da
renderização. Na prática, duas necessidades diferentes de organização
apareceram:

- organizações que sempre querem o texto atual da empresa vinculada
  (`company_id`, já implementado);
- organizações que querem um texto customizado — não necessariamente as
  linhas fixas nome/CNPJ/telefone, podem incluir qualquer coisa
  (`Empresa {{razão social}}`, `CNPJ {{...}}`, `Telefone {{...}}` foi o
  exemplo trazido, mas o texto é livre).

A ideia inicial (motor de placeholders `{{CAMPO}}` resolvido contra a
empresa) foi descartada em favor de uma mais simples: uma tela separada de
"modelos de etiqueta" onde o texto é digitado uma vez (com um pré-preenchido
opcional a partir de uma empresa) e fica congelado — selecionável na hora de
imprimir, sem re-resolver dado nenhum.

## Decisão

### Entidade nova, texto congelado, não um motor de template

`app.label_templates`: entidade de negócio padrão (7 colunas ADR-0006, RLS,
audit trigger — molde `equipment_types`) com `company_id` opcional (só
registra a origem/pré-preenchido) e `body` (texto livre, multilinha). O
texto salvo **não** volta a ler dado da empresa depois de criado — é
literal, exatamente o que o usuário confirmou. Isso evita todo o problema de
motor de placeholder (parsing, campos suportados, o que fazer se a empresa
mudar de nome) — o preço é que uma mudança de CNPJ, por exemplo, exige
editar o modelo manualmente (ou gerar um novo a partir da empresa
atualizada). Aceitável: o usuário decidiu explicitamente por essa
simplicidade em vez de dado vivo.

### `company_id` ao vivo e `template_id` congelado, lado a lado

Confirmado explicitamente: a opção já existente (`company_id`, ADR-0016)
continua. `labels.RequestBatchPDFInput` ganha `TemplateID *uuid.UUID` ao
lado de `CompanyID *uuid.UUID` — **mutuamente exclusivos**
(`ErrConflictingPDFSource` se os dois vierem preenchidos; nenhum dos dois,
a etiqueta sai só com QR + código, como já era). Mesma trava a nível de
banco em `app.label_batch_pdf_jobs`
(`CHECK ((company_id IS NOT NULL)::int + (template_id IS NOT NULL)::int <= 1)`,
molde do `qr_codes_entity_cardinality_ck` do ADR-0013) — defesa em
profundidade, não só validação de aplicação.

`internal/pdfjobs/labelrender.go` parou de receber um `emitter` estruturado
e passou a receber `infoLines []string` já resolvido pelo chamador — o
`LabelDispatcher` decide se essas linhas vêm de `emitterLines(comp)` (dado
vivo) ou de `strings.Split(template.Body, "\n")` (modelo congelado); o
renderizador não sabe a diferença, só desenha linhas de texto sob o código.

### Fluxo de criação com pré-preenchido: responsabilidade do cliente

A ideia de "ao criar uma empresa, perguntar se quer gerar o modelo" é um
fluxo de UI (Flutter, ainda não construído) — o backend só precisa oferecer
os dados para pré-encher: `POST /v1/label-templates` aceita `company_id`
opcional, e o cliente já tem `GET /v1/companies/{id}` para buscar
nome/CNPJ e montar o campo de texto inicial antes de deixar o usuário
editar e confirmar. Nenhuma rota nova só para isso.

### "Inativar quando a empresa mudar": não automático, o cliente pergunta

`company_id` em `label_templates` usa `ON DELETE SET NULL` (mesmo raciocínio
do `company_id` em `label_batch_pdf_jobs`, ADR-0016) — não é uma
dependência viva, é só rastro de origem. O backend **não** desativa nem
notifica automaticamente um modelo quando a empresa-mãe muda ou é
inativada — isso é UX do cliente: ele já sabe filtrar
`GET /v1/label-templates?company_id={id}` para achar os modelos derivados
de uma empresa e, se o usuário confirmar, chamar
`DELETE /v1/label-templates/{id}` (soft delete = "inativar") em cada um.
Nenhum acoplamento novo entre os pacotes `companies` e `labeltemplates`.

### "Inativar" = soft delete padrão, sem status extra

Cogitei um campo `active bool` separado do `deleted_at` de sempre — rejeitado:
o `deleted_at` já significa exatamente "não aparece mais para uso normal,
mas o histórico continua" em toda tabela do projeto (ADR-0006). Inventar um
segundo campo de estado só duplicaria semântica. `Delete` (soft delete) já
é "inativar".

### Limite de linhas/caracteres (spec §10.3)

`MaxLines = 6`, `MaxLineLength = 44` — folga física da célula de etiqueta
(60×42mm, ADR-0016) a ~7pt Helvetica. Validado na criação/edição
(`ErrTooManyLines`/`ErrLineTooLong`), não no banco — é regra de produto
ajustável, não invariante estrutural.

### Corrida rara: job pendente referenciando um modelo recém-inativado

Se um `template_id` for inativado enquanto um job de PDF ainda está
`pending` para ele, o worker vai falhar ao buscar o modelo
(`GetLabelTemplate` filtra `deleted_at IS NULL`) e o job entra no ciclo
normal de retry/backoff até `failed`. Não vale travar a inativação por causa
disso (janela de segundos, mesma disciplina de "erro raro vira retry" já
usada em outros jobs do worker).

### Bug sistêmico descoberto na verificação ao vivo: backfill de permissão silenciosamente vira no-op

`app.roles`, `app.role_permissions` e `app.organization_memberships` têm
`FORCE ROW LEVEL SECURITY` — a policy de tenant vale mesmo para o dono da
tabela (`servory_owner`, quem roda as migrations). O padrão de backfill
usado desde a migration 00010 (`INSERT ... SELECT ... FROM app.roles r ...`
+ `UPDATE app.organization_memberships SET permission_version = ...`) roda
sem contexto de tenant (`app.current_org()` é `NULL` fora de uma sessão de
aplicação) — a policy `organization_id = app.current_org()` não bate com
nenhuma linha, então o `INSERT`/`UPDATE` executa sem erro mas afeta **zero**
linhas para toda organização já existente antes da migration. Só
organizações criadas depois (via `organizations.Bootstrap`, sob contexto de
tenant de verdade) recebem a permissão nova corretamente.

Descoberto ao testar `label_template.create` ao vivo contra uma organização
de teste criada em sessão anterior: `FORBIDDEN` mesmo como admin.
`migrations/00031_label_template_permissions_backfill_fix.sql` corrige o
backfill desta entrega (`ALTER TABLE ... NO FORCE ROW LEVEL SECURITY` só ao
redor do backfill, restaurado ao final — migration nova, não edita a 00030
já aplicada). **Isto é um bug sistêmico** que afeta o mesmo padrão em toda
migration anterior que fez backfill de permissão (00010, 00016, 00017,
00022, etc.) — organizações criadas antes de cada uma delas rodar podem
estar com permissões faltando até hoje. Corrigir isso retroativamente para
todas as migrations antigas fica fora do escopo desta entrega (ver
`docs/progresso.md`).

## Consequências

- `migrations/00030_label_templates.sql`: tabela `app.label_templates` +
  catálogo de permissões `label_template.{read,create,update,delete}`
  (admin: tudo; technician/viewer: só leitura — mesmo padrão de
  `equipment_type`); `app.label_batch_pdf_jobs` ganha `template_id` +
  constraint de cardinalidade.
- `migrations/00031_label_template_permissions_backfill_fix.sql`: corrige o
  backfill de permissões de 00030 para organizações já existentes (ver
  "Bug sistêmico" acima).
- `internal/labeltemplates`: pacote novo, CRUD simples (molde
  `equipmenttypes`), rotas `/v1/label-templates`.
- `internal/labels/pdf.go`: `RequestBatchPDF` passa a receber
  `RequestBatchPDFInput` (struct) em vez de parâmetros posicionais —
  assinatura muda, únicos chamadores eram HTTP e testes (nenhum client
  externo ainda existe além do backend).
- `internal/pdfjobs/labelrender.go` e `labeljobs.go`: `renderLabelSheet`
  recebe `infoLines []string` em vez de `emitter`; `LabelDispatcher.process`
  resolve a fonte (empresa ou modelo) antes de renderizar.
- `openapi/openapi.yaml`: `LabelTemplate`/`LabelTemplateInput`, rotas CRUD,
  `template_id` no corpo de `POST /v1/qr-batches/{id}/pdf`.
- Testes: CRUD + validação de limite (`labeltemplates_test.go`), conflito
  `company_id`/`template_id` e modelo desconhecido (`labels/pdf_test.go`),
  pipeline completo com modelo salvo contra MinIO real
  (`pdfjobs/labeljobs_test.go`).
