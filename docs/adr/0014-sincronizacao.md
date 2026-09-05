# ADR-0014 — Sincronização: outbox por ponteiro, push idempotente, escopo do MVP

- **Status:** aceito
- **Data:** 2026-09-04
- **Contexto da spec:** §19, §22.7

## Contexto

O app Flutter precisa operar offline e sincronizar depois: enviar mudanças
locais (`push`) e baixar mudanças do servidor (`pull`), com um dump completo
na primeira instalação (`bootstrap`). A spec pede idempotência por
`operation_id`, concorrência otimista por `version`/`base_version`, política
de conflito por domínio (não "last write wins" universal — QR Code já tem a
sua, ADR-0013) e tombstones em vez de exclusão física.

## Decisão

### `outbox_events` guarda ponteiro, não payload

`app.outbox_events` é só `(seq, organization_id, entity_type, entity_id,
operation, occurred_at)` — um índice de "o que mudou", não o dado em si. O
`pull` usa o ponteiro pra buscar a linha **atual** na tabela de origem (via o
`Get` de cada entidade, que já aplica RLS e máscara de campo normalmente).

Rejeitada a alternativa óbvia — guardar o snapshot do registro no próprio
evento (como o `payload` do `sync_outbox` **do cliente**, spec §19.3). No
servidor isso duplicaria dado, ficaria desatualizado se o registro mudasse nas
edições seguintes e escaparia da máscara de campo/RLS (o snapshot teria sido
gravado com o contexto de quem fez a mudança, não de quem está puxando). Como
ponteiro, o `pull` sempre devolve o estado atual de verdade, já filtrado pela
permissão de quem está perguntando — inclusive um tombstone (`deleted_at`
setado) é só mais um "estado atual" normal.

`seq` é `bigint GENERATED ALWAYS AS IDENTITY` — monotônico, serve de cursor
direto (`?cursor=<seq>`), sem precisar de timestamp (que pode empatar) nem
sequência separada por tabela.

### Trigger genérico, não um trigger por entidade

Uma função `app.record_outbox_event()` só, parametrizada pelo nome da
entidade via `TG_ARGV[0]`, anexada a cada tabela participante — mesmo padrão
de `audit.capture_row_change()` (ADR-0005). Detecta "delete" pela transição
`deleted_at NULL → NOT NULL` dentro de um `UPDATE` (soft delete, ADR-0006),
não por `TG_OP = 'DELETE'` — exclusão física quase nunca acontece nessas
tabelas.

### Push reaproveita os serviços existentes, não reimplementa regra de negócio

`internal/sync` não sabe validar um cliente ou aplicar RLS — ele chama
`clients.Service.Create/Update/Delete` como qualquer handler HTTP chamaria.
Um adaptador por tipo de entidade (`Adapter` interface: `Get`, `ApplyCreate`,
`ApplyUpdate`, `ApplyDelete`, `List`) faz a ponte entre o `payload` genérico
do push (`json.RawMessage`) e o `Input` tipado de cada pacote — a decodificação
do JSON fica no **próprio pacote da entidade** (`clients.DecodeSyncPayload`),
não duplicada em `internal/sync`, pra não ter duas listas de campos por
entidade divergindo com o tempo.

Concorrência otimista do push reaproveita o `ErrVersionConflict` que cada
`Update` já devolve — não é um mecanismo novo, é o mesmo de `PATCH
/v1/clients/{id}`. Conflito de `create` (colisão de ID gerado pelo
dispositivo, extremamente raro com UUID) e `delete` (idempotente por natureza
— apagar de novo não é erro) seguem a mesma semântica do REST já existente.

Idempotência por `operation_id`: `app.sync_applied_operations` (chave
primária o próprio `operation_id`) guarda o resultado da primeira aplicação;
uma repetição do mesmo `operation_id` devolve o resultado gravado sem
reexecutar nada.

### Criação com ID vindo do cliente

Spec §19.1: entidades criadas offline usam UUID gerado no dispositivo, nunca
uma sequence do servidor. Isso quebra a suposição de `Create` (sempre gera o
próprio ID via `s.ids.New()`) — resolvido com um método adicional
(`CreateWithID`) que aceita o ID e reusa toda a lógica interna de `Create`;
o `Create` público (`POST /v1/clients`) continua gerando o próprio ID, sem
mudança de comportamento pra quem já usa a API síncrona.

## Escopo desta entrega

Toda a infraestrutura (`outbox_events`, trigger genérico, `sync_applied_
operations`, `push`/`pull`/`bootstrap`) está pronta e testada. Ligar mais uma
entidade é mecânico e sempre os mesmos 4 passos, sem decisão nova:

1. anexar o trigger genérico na migration da tabela (`... EXECUTE FUNCTION
   app.record_outbox_event('<entity_type>')`);
2. escrever `<pacote>.DecodeSyncPayload` — ou, quando o serviço já separa
   `CreateInput`/`UpdateInput` (locations), `DecodeCreateSyncPayload` +
   `DecodeUpdateSyncPayload` — decodificando o mesmo `body` que o HTTP já usa;
3. adicionar `CreateWithID` ao serviço, se ainda não existir;
4. registrar um `Adapter` em `internal/sync/adapters.go` e no map de
   `sync.New(...)` em `cmd/servicelog-api/deps.go`.

**2026-09-04:** `locations` e `equipments` ligados seguindo essa receita
(migration `00028`). Único ajuste real sobre a prova original com `clients`:
`locations.Get/List` devolvem `View` (struct tipado, sem máscara de campo por
permissão — a entidade não tem campo sensível), não `map[string]any` como
`clients`/`equipments` — o adaptador converte via round-trip JSON
(`structToMap` em `internal/sync/adapters.go`) em vez de reusar o mapa
direto. `equipments` seguiu exatamente o molde de `clients` (já devolvia
`map[string]any` com máscara de campo, `serial_number`/`cost`).

**2026-09-05:** `service_orders` (cabeçalho + peças) ligado — ver
`ADR-0018`, que resolve exatamente as perguntas em aberto acima:
transições de estado (`start`/`complete`/`reopen`) viram `operation_type`
novos aplicados por uma interface opcional (`sync.ActionApplier`); uma
transição feita offline não é bloqueada, só vira `conflict` se o estado do
servidor não bater mais quando o dispositivo sincronizar. Fotos/assinatura/
PDF continuam de fora (blob-backed, protocolo próprio).

**2026-09-05 (2):** `qr_code`/`qr_batch` ligados — ver `ADR-0019`.
`ActionApplier.ApplyAction` ganhou um parâmetro `payload` (etiqueta precisa
de dado extra em `assign`/`replace`, que `service_order` nunca precisou) e o
dispatch de ações em `internal/sync/sync.go` deixou de hardcodar nomes
(`"start", "complete", "reopen"`) — qualquer `operation_type` fora de
create/update/delete tenta `ActionApplier` genericamente. `qr_batch` é só
leitura do lado do dispositivo (mutação de lote é sempre trabalho de
escritório, via REST). Com isso, todas as entidades do roadmap original de
sincronização estão ligadas.

Fora do escopo (não é decisão adiada, é trabalho de outra camada):

- **Fila local (`sync_outbox`) e motor offline no Flutter** — spec §19.3,
  §19.4; é código do app, não do backend.
- **`Idempotency-Key` genérico em endpoints não-sync** (spec §22.1 menciona
  como convenção geral da API) — só o `push` de sincronização ganhou
  idempotência agora, via `operation_id`; os demais endpoints REST seguem sem.
- **Retenção/expurgo de `outbox_events`** — cresce sem limite por ora; um
  job de expurgo (como `audit.purge_older_than`) fica para quando o volume
  justificar.
- **Fotos/assinatura/PDF no fluxo de sync** — são blob-backed e já têm seu
  próprio protocolo de upload (ADR-0012); entram na sincronização só como
  metadados quando alguma entidade que os referencia for ligada.

## Alternativas consideradas

- **Reusar `audit.row_history` como changefeed** — rejeitada: é diff
  coluna-a-coluna (uma linha por coluna alterada), pensado para forense, não
  para reconstruir o estado atual de um registro; obrigaria o cliente a
  reaplicar patches em vez de sempre receber o estado atual.
- **Payload no próprio evento do outbox** — ver "Decisão" acima.
- **Um cursor por tabela em vez de uma tabela `outbox_events` única** — mais
  simples de escrever (não precisa de trigger), mas o `pull` teria que fazer
  *N* consultas (uma por tipo de entidade) e intercalar os resultados por
  tempo para dar um cursor único e estável ao cliente — a tabela única com
  `seq` global resolve isso de graça.

## Consequências

- `app.outbox_events` cresce a cada INSERT/UPDATE em tabela participante —
  ver retenção acima, item futuro.
- Toda tabela que entrar na sincronização precisa de `organization_id` e
  `id` nas colunas exatamente com esse nome (o trigger genérico assume isso)
  — já é o padrão de toda `app.*` desde ADR-0006, então não é uma restrição
  nova.
- `internal/sync` depende dos pacotes de cada entidade (import direto do
  `Service` de `clients`, depois `locations` etc.) — acoplamento aceitável,
  é a camada que **deveria** conhecer todo mundo; nenhuma entidade depende de
  `sync` de volta.
