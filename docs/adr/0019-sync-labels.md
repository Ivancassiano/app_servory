# ADR-0019 — Sincronização de etiquetas/QR Codes e lotes

- **Status:** aceito
- **Data:** 2026-09-05
- **Contexto da spec:** §19 (sincronização), §8-§12 (etiquetas/QR Codes),
  §11.2 (reserva de lote para trabalho offline)

## Contexto

ADR-0014/0018 deixaram `qr_code`/`qr_batch` de fora ("ficam para quando o
app Flutter precisar" — só faltava mesmo implementar). Como `service_order`,
etiqueta não é CRUD simples: não tem "editar campos" (só transições
nomeadas — vincular, substituir, desativar) e tem uma trava de concorrência
própria que **não usa `version`** (ADR-0013, "primeira confirmação vence"
por `UPDATE` condicional). Isso levantou duas perguntas que ADR-0018 não
respondia:

1. Como uma transição nomeada (`assign`/`replace`/`deactivate`) carrega dado
   extra (o destino de um vínculo, o ID de uma etiqueta substituta) quando
   `sync.ActionApplier.ApplyAction` (ADR-0018) não recebia `payload`?
2. `Replace` mexe em **duas** etiquetas (a antiga vira `replaced`, a nova
   fica `assigned`) — qual das duas o protocolo de sync deveria reportar
   como resultado da operação?

## Decisão

### `ActionApplier.ApplyAction` ganha `payload`; o dispatch de ações vira genérico

Antes, `internal/sync/sync.go` tinha um `case "start", "complete", "reopen":`
hardcoded — funcionava porque nenhuma dessas transições precisava de dado
além do `id`/`base_version` já trafegados. `assign` quebra essa suposição
(precisa saber vincular a quê). Duas mudanças, sem afetar o comportamento
de `service_order`:

- `ApplyAction` ganha um quinto parâmetro, `payload json.RawMessage` —
  `service_order` simplesmente ignora (nenhuma das suas três transições
  precisa de dado extra); `qr_code` usa para decodificar o destino
  (`assign`) ou o ID da etiqueta substituta (`replace`).
- O `switch` em `applyOne` perde o `case` com nomes hardcoded — qualquer
  `operation_type` que não seja `create`/`update`/`delete` cai no `default`,
  que testa `ActionApplier` e delega. O **nome** da ação (`"start"` vs.
  `"assign"`) só é conhecido pelo adaptador de cada entidade; `internal/sync`
  nunca precisou saber a lista — continuar hardcoding os nomes ali só
  criaria uma segunda lista para manter sincronizada a cada nova entidade
  com transições, contrariando o "ligar mais uma entidade é mecânico" do
  ADR-0014.

### `assign`/`replace`/`deactivate` não usam `base_version` — a trava já existe

Diferente de `service_order` (cujas transições exigem `version` porque o
resto da entidade também usa `version`), etiqueta nunca teve trava por
`version` (ADR-0013): o próprio `UPDATE ... WHERE status IN (...)` de
`Assign`/`Replace`/`Deactivate` já é a trava — 0 linhas afetadas quando
outro dispositivo (ou o próprio usuário, online, entre duas sincronizações)
já mudou o status é detectado e vira `ErrCodeNotAvailable`/
`ErrEntityAlreadyLabeled`/`ErrCodeNotAssigned`, que `qrCodeResult` traduz
para `sync.ErrConflict` — mesma família do conflito de `version`: o
dispositivo estava com uma visão desatualizada da etiqueta ou do destino.
`base_version` continua obrigatório no protocolo (regra genérica de
`applyOne` para qualquer ação, não seria coerente exigi-lo só de algumas
entidades), mas `qrCodeAdapter.ApplyAction` não precisa consultá-lo.

### `Replace` reporta o estado da etiqueta **antiga**, não da nova

O protocolo de push amarra o resultado (`OperationResult.EntityID`/
`.Version`) ao `entity_id` que o dispositivo enviou — sempre a etiqueta
antiga em um `replace` (é o objeto que o dispositivo tinha em mãos e queria
substituir; a nova pode nem ter ID conhecido do dispositivo, se
`new_code_id` veio vazio e o servidor gerou um código novo). Devolver o
`version`/estado da etiqueta **nova** sob o `entity_id` da antiga seria
inconsistente com o resto do protocolo. Resolvido fazendo o adaptador, após
`Replace` ter sucesso, buscar de novo o estado da etiqueta antiga
(`status = 'replaced'`) para compor a resposta — a etiqueta nova aparece
no próximo `Pull` como qualquer outra entidade alterada (o `INSERT`/`UPDATE`
dela já dispara o trigger de outbox normalmente), sem precisar inventar um
segundo "resultado" dentro de uma única `OperationResult`.

### `qr_batch`: só leitura do lado do dispositivo

Diferente de `qr_code`, um lote nunca é criado/mutado no campo — criar,
reservar para um técnico, exportar (gerar o PDF de impressão) e marcar
perdido são decisões de escritório (spec §9), sempre pelo REST de sempre.
O que o dispositivo precisa é **ver** que um lote foi reservado para ele
(spec §9.1/§11.2 — o passo que precede levar etiquetas físicas pré-geradas
para o campo e trabalhar com elas offline via `qr_code`). Por isso
`qrBatchAdapter` implementa `Get`/`List` normalmente (entra no `Pull` e no
`Bootstrap`) mas `ApplyCreate`/`ApplyUpdate`/`ApplyDelete` sempre devolvem
`ErrOperationNotSupported` — nenhuma mutação de lote entra pelo push.

### `qr_code` criado offline: o `public_code` continua sempre gerado pelo servidor

`CreateWithID` (novo, mesmo molde de `clients`/`locations`/`equipments`/
`service_order`) aceita o `id` (UUID, chave primária) gerado pelo
dispositivo, mas o texto do código público (~80 bits via `crypto/rand`,
ADR-0013) continua gerado no servidor — não faz sentido o dispositivo
"escolher" um valor desse formato offline, e a checagem de unicidade
depende do banco. Isso é coerente com a realidade de campo: a maioria das
etiquetas já existe fisicamente antes de qualquer sincronização (impressas
de um lote — spec §9), então `ApplyCreate` cobre sobretudo o caso raro de
uma etiqueta "avulsa" criada ad-hoc; o caminho comum é `assign` numa
etiqueta que já existe (do lote reservado) escaneada em campo.

## Consequências

- `migrations/00033_sync_labels.sql`: trigger genérico anexado a
  `app.qr_codes` (`qr_code`) e `app.qr_batches` (`qr_batch`);
  `app.qr_assignment_attempts` fica de fora (é log de tentativas, não
  registro de negócio sincronizável).
- `internal/labels`: `CreateWithID` (mesmo molde das demais entidades);
  `ListAll` novo (bootstrap — não existia leitura "todas as etiquetas da
  org", o resto do pacote sempre parte de um lote/destino conhecido);
  `internal/labels/sync.go` novo (`DecodeCreateSyncPayload`/
  `DecodeAssignSyncPayload`/`DecodeReplaceSyncPayload`, reusam os bodies do
  HTTP).
- `internal/sync/registry.go`: `ActionApplier.ApplyAction` ganha `payload
  json.RawMessage`.
- `internal/sync/sync.go`: dispatch de ações generalizado (não hardcoda mais
  nomes); `serviceOrderAdapter.ApplyAction` ajustado à nova assinatura
  (ignora o payload, nenhuma mudança de comportamento).
- `internal/sync/adapters.go`: `qrCodeAdapter` (implementa `ActionApplier`;
  `ApplyUpdate`/`ApplyDelete` sempre `ErrOperationNotSupported`) e
  `qrBatchAdapter` (só leitura — as três `Apply*` de escrita sempre
  `ErrOperationNotSupported`); registrados em `cmd/servicelog-api/deps.go`.
- `openapi.yaml`: enum de `operation_type` corrigido para listar todas as
  transições nomeadas existentes (estava desatualizado desde o ADR-0018 —
  só listava `create/update/delete`).
- Testes: criação de etiqueta livre + pull; `assign` via push (com e sem
  conflito de destino já vinculado); `replace`+`deactivate` em sequência
  via push; `update`/`delete` de etiqueta rejeitados; lote aparece em
  pull/bootstrap mas rejeita mutação pelo push.
- Com esta entrega, todas as entidades de negócio do roadmap original de
  sincronização estão ligadas (`client`, `location`, `equipment`,
  `service_order`+peças, `qr_code`+`qr_batch`) — não há mais nenhuma
  entidade pendente conhecida.
