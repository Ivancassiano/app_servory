# ADR-0018 — Sincronização de ordens de serviço e transições de estado

- **Status:** aceito
- **Data:** 2026-09-05
- **Contexto da spec:** §19 (sincronização), §7.6 (máquina de estados da ordem)

## Contexto

ADR-0014 deixou `service_orders` de fora da sincronização porque a entidade
tem máquina de estados (`draft → open → in_progress → completed`, com
`reopen` de volta a `in_progress`) e sub-recursos (peças, fotos, assinatura,
PDF) — não é receita mecânica pura como `locations`/`equipments` foram.
Durante a conversa que motivou esta entrega, surgiram duas dúvidas que
precisavam de resposta antes de implementar:

1. Transições de estado feitas offline (iniciar/concluir/reabrir) exigem que
   o dispositivo esteja online nesse momento, ou podem ser enfileiradas como
   qualquer outra mudança?
2. O laudo em PDF (hoje só gerado no servidor, `internal/pdfjobs`) precisa
   ficar disponível no dispositivo mesmo offline?

## Decisão

### Transições de estado são só mais um tipo de operação de push — sem bloqueio offline

Não há motivo para exigir conexão para iniciar/concluir/reabrir uma ordem.
O protocolo de sync já resolve exatamente esse problema para create/update
via `version`/`base_version` (concorrência otimista) — uma transição de
estado nada mais é que uma operação que só é válida a partir de um estado
específico do servidor; tratá-la como "mais um tipo de conflito" (em vez de
inventar uma trava de conectividade) reaproveita o mecanismo que já existe.

Consequência prática: `sync.Operation.OperationType` ganha três valores além
de `create`/`update`/`delete`: `start`, `complete`, `reopen`. Uma nova
interface opcional, `sync.ActionApplier`
(`ApplyAction(ctx, p, reqID, id, action, baseVersion)`), é implementada só
pelo adaptador de `service_order` — os demais adaptadores (`clients`,
`locations`, ...) não precisam de nada novo, o dispatcher (`internal/sync/
sync.go`) testa a interface em runtime (`adapter.(ActionApplier)`) antes de
rejeitar um `operation_type` desconhecido.

Tentar uma transição inválida no estado atual do servidor (ex.: `complete`
numa ordem que não está `in_progress` — o dispositivo estava com uma visão
desatualizada) vira `ErrConflict`, a mesma família do conflito de `version`
— não é um erro genérico, é sinalizado ao app exatamente como "sua cópia
local está desatualizada, puxe de novo".

### `service_order` não aceita `delete` — rejeição explícita, não erro genérico

A API síncrona nunca expôs `DELETE /v1/service-orders/{id}` (não existe
regra de negócio para apagar uma ordem — só peças/fotos/recomendações
individuais são removíveis). O adaptador de sincronização devolve um erro
sentinela novo, `sync.ErrOperationNotSupported`, mapeado para
`rejected/BAD_OPERATION_TYPE` — o mesmo código que uma operação
verdadeiramente desconhecida já usa, em vez de cair no `default` genérico
(que logaria como erro interno algo que é, na verdade, uma rejeição
esperada e sempre reproduzível).

### Peças (`service_order_part`): entidade própria, sem "dono" fixo no protocolo

O protocolo de sync só recebe `entity_id` — uma peça não carrega consigo a
ordem-pai automaticamente. Isso expôs uma lacuna real nos métodos
existentes: `UpdatePart`/`DeletePart`/`loadPart` exigiam `orderID` **e**
`partID` (a rota REST aninhada `/service-orders/{id}/parts/{partId}` sempre
tem os dois). Resolvido generalizando `loadPart` para aceitar
`expectOrderID *uuid.UUID` — `nil` (usado pelo adaptador de sync, que só tem
o ID da peça) pula a checagem de pertencimento; um valor (usado pela rota
REST) mantém a checagem de sempre. `UpdatePartByID`/`DeletePartByID`/`GetPart`
são as variantes novas "só pelo próprio ID"; `UpdatePart`/`DeletePart`
continuam exatamente como eram para a REST. Criação não precisou dessa
generalização — o payload de criação de uma peça sempre carrega
`service_order_id` explicitamente (like `client_id` no payload de criação de
um local), então `AddPartWithID` reusa a assinatura que já recebe `orderID`.

`ListAllParts` (nova, paginada por organização inteira, não por ordem) supre
o `List`/bootstrap do adaptador — não existia antes porque toda leitura de
peças até aqui partia de uma ordem conhecida (`GET
/v1/service-orders/{id}/parts`).

### Bug real encontrado ao testar: `version` sumia em entidades convertidas por `structToMap`

`locations` e agora `service_order` devolvem `View` tipado, convertido para
`map[string]any` via round-trip JSON (`structToMap`, ADR-0014). Um número
`int32` nativo, depois de passar por esse round-trip, volta como `float64`
(`json.Unmarshal` sempre decodifica número em `float64` para uma interface
genérica) — o código que extraía `out["version"]` em `internal/sync/sync.go`
fazia um type assertion direto para `int32`, que falhava silenciosamente
para essas entidades, deixando `OperationResult.Version` sempre `nil` em
operações bem-sucedidas. Isso já afetava `locations` desde a entrega
anterior — nenhum teste checava `Version` num push de local, então passou
despercebido até o primeiro teste de transição de ordem checar explicitamente
o `version` devolvido. Corrigido com um helper (`versionOf`) que aceita os
dois formatos (`int32` nativo ou `float64` do round-trip).

### PDF: continua fora do sync — e o PDF "de campo" é responsabilidade do Flutter, não do backend

Reconfirma ADR-0014: laudo em PDF não sincroniza (é blob-backed, protocolo
de upload próprio). Ficou explícito na conversa que, para o técnico ter um
PDF em mãos mesmo sem conexão, o **Flutter precisa gerar seu próprio PDF
localmente** (a partir dos dados já no dispositivo — diagnóstico, peças,
fotos, assinatura, tudo já capturado offline) — o PDF do servidor
(`internal/pdfjobs`) continua sendo a cópia oficial/canônica, gerada quando
a ordem sincroniza, para acesso de qualquer lugar. São dois artefatos com
propósitos diferentes, não uma duplicação a resolver; nenhuma mudança de
backend decorre disso — fica registrado aqui só para não se perder a
decisão.

## Consequências

- `migrations/00032_sync_service_orders.sql`: trigger genérico anexado a
  `app.service_orders` (`service_order`) e `app.service_order_parts`
  (`service_order_part`).
- `internal/serviceorders`: `CreateWithID` (ordem) e `AddPartWithID` (peça)
  novos; `GetPart`/`UpdatePartByID`/`DeletePartByID`/`ListAllParts` novos
  (usados pelo adaptador de sync, mas são métodos públicos comuns, nada
  exclusivo de sync); `loadPart` generalizado (`expectOrderID *uuid.UUID`).
- `internal/serviceorders/sync.go`: `DecodeCreateSyncPayload`/
  `DecodeUpdateSyncPayload` (cabeçalho), `DecodeCreatePartSyncPayload`/
  `DecodeUpdatePartSyncPayload` (peça).
- `internal/sync/registry.go`: interface opcional `ActionApplier`.
- `internal/sync/sync.go`: `applyOne` aceita `start`/`complete`/`reopen`
  quando o adaptador implementa `ActionApplier`; `ErrOperationNotSupported`
  novo; `versionOf` corrige a extração de `version` pós-`structToMap`.
- `internal/sync/adapters.go`: `serviceOrderAdapter` (implementa
  `ActionApplier`; `ApplyDelete` sempre `ErrOperationNotSupported`) e
  `serviceOrderPartAdapter`; registrados em `cmd/servicelog-api/deps.go`.
- Testes: criação/atualização/conflito de versão do cabeçalho; as três
  transições em sequência via push; transição inválida vira conflict;
  delete rejeitado; CRUD completo de peça via sync + bootstrap.
