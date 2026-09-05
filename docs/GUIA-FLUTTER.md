# Guia: desenvolvimento do aplicativo Flutter

> **Para quem:** o desenvolvedor (humano ou Claude) que vai criar o app
> Flutter consumindo este backend — Fase 2 em diante da spec.
>
> **Ponto de partida:** o backend está **completo** (Fases 0–1, 3–6 da spec —
> ver `docs/progresso.md`). Não falta nenhum endpoint, migration ou decisão de
> arquitetura de servidor conhecida para o app começar. Este guia documenta
> **o contrato que o backend já oferece** e como um cliente Flutter deve
> consumi-lo — não é um guia de "como escrever Flutter" (widgets, state
> management etc.), é sobre a integração com este backend específico.
>
> Ordem de leitura recomendada: este guia → `servicelog-especificacao-
> funcional-tecnica.md` §4, §11–§12, §16–§19, §26.4 (as regras de produto e
> offline não mudam) → `openapi/openapi.yaml` (contrato exato de cada
> endpoint — é a fonte de verdade, não o §22 da spec, que é só o rascunho
> original) → ADRs citados ao longo deste guia.

---

## 0. TL;DR

1. **Dois hosts, dois papéis.** `auth-api` (login/refresh/sessões) assina
   token com a chave privada; `servicelog-api` (tudo mais) só verifica. Do
   ponto de vista do app, é só roteamento por caminho — ver §2.
2. **Permissão é decoração de UI, nunca segurança.** O app pode/deve
   esconder botões com base em `GET /v1/me/permissions`, mas o servidor
   sempre reforça de novo — nunca confie só na interface (spec §17.4).
3. **Nem toda entidade sincroniza offline.** Só 7 tipos têm suporte a
   criar/editar sem internet (client, location, equipment, service_order +
   peças, qr_code, qr_batch — leitura). Tudo o resto (empresas, tipos de
   equipamento/serviço, contatos, modelos de etiqueta, fotos, assinatura,
   PDF, recomendações) **exige conexão** — ver §8.4.
4. **`version` é sempre a trava de concorrência**, exceto etiqueta (usa
   status, não version — ver §9). Toda entidade sincronizável carrega
   `version` no pull; toda edição via push exige `base_version`.
5. **O PDF do laudo tem duas cópias por design, não por acidente**: o
   servidor gera a oficial quando a ordem sincroniza; o app **precisa**
   gerar a sua própria localmente para o técnico sair de campo com o laudo
   em mãos mesmo offline (ADR-0018 — decisão já tomada, não é bug).
6. **UUID sempre gerado pelo dispositivo**, nunca peça um ID ao servidor
   antes de criar algo offline — é assim que o protocolo de sync funciona
   (spec §19.1).

---

## 1. O que já existe pronto (não reimplementar, não redesenhar)

| Camada | Onde está | Estado |
|---|---|---|
| Autenticação (login, refresh, sessões, revogação) | `auth-api` | ✅ completo |
| Multitenancy + RLS + permissões por campo | `internal/permissions`, RLS em toda tabela | ✅ completo |
| Cadastros (clientes PF/PJ, locais com hierarquia, equipamentos, tipos, empresas, pessoas, contatos) | `servicelog-api` | ✅ completo |
| Ordens de serviço (cabeçalho, peças, fotos, assinatura, recomendações, PDF) | `servicelog-api` + `worker` | ✅ completo |
| Etiquetas/QR Code (criar, vincular, substituir, desativar, lotes, PDF de impressão em 3 layouts) | `servicelog-api` + `worker` | ✅ completo |
| Sincronização (push/pull/bootstrap, outbox, idempotência, conflito por versão) | `internal/sync` | ✅ completo (7 entidades ligadas) |
| OpenAPI (schema de cada endpoint) | `openapi/openapi.yaml` | ✅ atualizado a cada mudança |

O que **não** existe e é 100% trabalho do Flutter (nada bloqueado no
backend, spec §28 Fase 2):

- app em si (estrutura, navegação, telas — spec §6);
- banco local SQLite/Drift + outbox local (spec §18–§19.3);
- fila de upload de anexo com retomada (spec §19.7);
- sessão offline por PIN/biometria (spec §18.3);
- geração do PDF do laudo **no dispositivo** (ADR-0018, §10 abaixo).

---

## 2. Arquitetura: dois hosts

```text
https://seudominio.com/v1/auth/*   →  auth-api      (login, refresh, sessões, senha)
https://seudominio.com/v1/*        →  servicelog-api (tudo mais: cadastros, ordens,
                                                       etiquetas, sync, /v1/me)
```

Em produção os dois ficam atrás do mesmo domínio/proxy (ver
`docs/deploy-vps.md`) — o app não precisa saber que são processos
diferentes, só que `/v1/auth/*` é um grupo de rotas e o resto é outro.
`GET /v1/me` funciona nos dois lados (ADR-0004) por conveniência de teste,
mas o app deve sempre chamá-lo pelo host principal.

---

## 3. Autenticação

### 3.1 Login

```http
POST /v1/auth/login
{
  "email": "tecnico@empresa.com",
  "password": "...",
  "device": { "id": "uuid-gerado-uma-vez-por-instalação", "name": "Moto G54", "platform": "android" }
}
```

`device.id` é um UUID que o app gera **uma vez** na primeira instalação e
persiste para sempre (não é o mesmo a cada login) — é o que liga sessão,
refresh token e sessão offline a "este aparelho específico" (spec §16.3).
Resposta (`200`):

```json
{
  "access_token": "eyJ...",
  "refresh_token": "opaco-aleatorio",
  "token_type": "Bearer",
  "access_expires_at": "2026-...Z",
  "refresh_expires_at": "2026-...Z",
  "organization_id": "uuid",
  "user_id": "uuid"
}
```

Não existe seleção de organização no login (decisão definitiva, spec §29.4)
— o usuário já entra direto na organização ativa.

### 3.2 Usar o access token

`Authorization: Bearer <access_token>` em toda chamada (exceto
`/auth/login`, `/auth/refresh`, `/auth/password/*`). Dura **10 minutos**
por padrão (`ACCESS_TOKEN_TTL`) — o app deve tratar `401` como "token
expirou, tenta refresh" em qualquer request, não só numa tela específica.

### 3.3 Refresh

```http
POST /v1/auth/refresh
{ "refresh_token": "..." }
```

Devolve um par novo (access + refresh) — o refresh token é **de uso único**
e rotaciona a cada chamada (spec §16.2). Guarde sempre o token novo,
descarte o antigo. Se o refresh falhar com `401`/`REUSED_TOKEN` (o backend
detecta reuso de um token já rotacionado — indício de token roubado), a
sessão inteira foi revogada: force logout local e peça login de novo.

### 3.4 Sessão offline (spec §18.3)

O primeiro login **exige internet**. Depois disso, o app pode continuar
funcionando sem rede desde que a última validação online tenha sido há
menos de **7 dias** (padrão, configurável por organização no futuro) — essa
janela é um **relógio local do app**, o servidor não tem como avisar
proativamente que expirou enquanto o aparelho está offline. Ao voltar a
ficar online, o app deve:

1. Tentar `POST /v1/auth/refresh` imediatamente.
2. Se falhar, tratar como "sessão inválida" — não continuar oferecendo
   acesso aos dados locais mesmo que o cache ainda exista.
3. Re-sincronizar (`pull`) antes de aceitar que os dados locais estão
   corretos — permissões/associação podem ter mudado enquanto offline.

Nada disso tem endpoint dedicado — é lógica 100% do app em cima do
`refresh` normal.

### 3.5 Logout / revogação

```http
POST /v1/auth/logout           # sessão atual
POST /v1/auth/logout-all       # todas as sessões do usuário
GET  /v1/auth/sessions         # lista sessões/dispositivos ativos
DELETE /v1/auth/sessions/{id}  # revoga uma sessão específica (ex.: "sair remotamente")
```

---

## 4. Permissões no cliente (UI apenas)

```http
GET /v1/me/permissions
GET /v1/me
```

`/v1/me/permissions` devolve a lista de chaves concedidas (`client.read`,
`equipment.cost.read`, ...) — use para **esconder/desabilitar** botões e
campos, nunca para decidir se uma operação é permitida de verdade (spec
§17.4). O JWT carrega `permission_version`; quando ela muda (perfil ou
permissão do usuário foi alterada), o cache local de permissões fica
desatualizado — refaça o `GET /v1/me/permissions` sempre que notar essa
claim diferente do que está salvo.

**Máscara de campo real** vem embutida nas próprias respostas dos
endpoints de negócio, não numa lista à parte: um campo sensível
(`internal_notes`, `serial_number`, `cost`, `unit_cost`/`unit_price`, ...)
**simplesmente não aparece** no JSON quando o usuário não tem `.read`
naquele campo, e a escrita é rejeitada com `422` se ele não tem `.write`.
O app deve tratar a ausência de uma chave como "sem permissão para ver
isso", não como `null`/vazio.

---

## 5. Banco local (SQLite/Drift) — decisão de arquitetura, não deste backend

Spec §18: SQLite via Drift, **um arquivo por organização**
(`servicelog-{organization_id}.sqlite`), banco **criptografado** com a
chave no Keychain/Keystore do SO. A biblioteca exata de criptografia
compatível com todas as plataformas-alvo (Android/iOS/Windows/macOS) é uma
**decisão em aberto do lado Flutter** (spec §30) — o backend não impõe
nada aqui, só espera que os dados que ele manda por `pull`/`bootstrap`
sejam armazenados com segurança equivalente à de um banco de produção
(são os mesmos dados sensíveis que o Postgres protege com RLS).

O schema local não precisa espelhar exatamente as tabelas do Postgres —
precisa guardar, por registro sincronizável, os metadados do protocolo:

```text
id                  -- mesmo UUID do servidor
organization_id
version             -- version que o servidor confirmou (não usar para qr_code)
sync_status         -- synced | pending | conflict
local_updated_at
last_synced_at
sync_error
```

mais uma tabela de outbox (§8.2) e uma fila de upload de anexo (§7).

---

## 6. API REST (cadastros, ordens, etiquetas — quando online)

Convenções gerais (`openapi/openapi.yaml` §info, válidas em toda rota):

- `/v1` prefixo, JSON, datas ISO 8601 UTC, IDs como string UUID.
- Envelope de erro sempre:
  ```json
  { "error": { "code": "NOT_FOUND", "message": "...", "details": {}, "request_id": "uuid" } }
  ```
  `code` é estável e em inglês (SNAKE_CASE) — trate por `code`, nunca por
  `message` (mensagem é só para log/debug, não é para traduzir e mostrar
  como está).
- Optimistic locking: toda entidade com `version` exige `version` no corpo
  de `PATCH`; servidor devolve `409`/`CONFLICT` se estiver desatualizado.
- Upload de arquivo é sempre `multipart/form-data` com o campo chamado
  **`file`** (fotos, assinatura, logo da empresa) — o `Content-Type` que o
  app manda é ignorado pelo servidor por segurança; ele detecta o tipo real
  pelos bytes (JPEG/PNG só). Baixe **sempre** pela URL assinada que o
  endpoint de download devolve (nunca existe um jeito de pegar o binário
  direto do endpoint de metadados).

Grupos de endpoint (consulte `openapi.yaml` para o schema exato de cada
um — não duplicado aqui para não desatualizar):

| Grupo | Prefixo |
|---|---|
| Organização, usuários, perfis, permissões | `/v1/organization`, `/v1/users`, `/v1/roles`, `/v1/permissions` |
| Pessoa (dados do próprio usuário) | `/v1/me/person` |
| Empresas (emitente de laudo/etiqueta) | `/v1/companies` (+ `/members`, `/logo`) |
| Clientes | `/v1/clients` (+ `/contacts`) |
| Locais | `/v1/locations` (+ `/contacts`, `/parent` p/ reparent) |
| Tipos de equipamento/serviço | `/v1/equipment-types`, `/v1/service-order-types` |
| Equipamentos | `/v1/equipments` |
| Ordens de serviço | `/v1/service-orders` (+ `/start`,`/complete`,`/reopen`,`/parts`,`/photos`,`/signature`,`/recommendations`,`/pdf`) |
| Etiquetas/QR Code | `/v1/qr-codes` (+ `/assign`,`/replace`,`/deactivate`,`/resolve/{code}`), `/v1/qr-batches` (+ `/reserve`,`/export`,`/mark-lost`,`/pdf`) |
| Modelos de etiqueta (texto congelado) | `/v1/label-templates` |
| Auditoria | `/v1/audit` |
| Sincronização | `/v1/sync/push`, `/v1/sync/pull`, `/v1/sync/bootstrap` |

---

## 7. Upload de anexo com fila offline (spec §19.7)

Fotos e assinatura de ordem, e logo de empresa, são upload binário — não
fazem parte do protocolo de sync (payload de sync é sempre JSON). Regra
para o app:

1. Salvar o arquivo localmente assim que capturado (câmera/assinatura na
   tela), independente de estar online.
2. Criar um item de fila local: `{ entity_type, entity_id, file_path,
   sha256, attempts, last_error }`.
3. Quando online, fazer o `POST multipart` de verdade; em caso de sucesso,
   remover da fila; em caso de falha de rede, manter e tentar de novo
   depois (suportar retomada — não precisa reenviar o arquivo inteiro do
   zero se a lib de HTTP usada suportar upload resumível).
4. **Não marcar a ordem de serviço como "totalmente sincronizada"** enquanto
   houver anexo obrigatório pendente nessa fila — mesmo que o cabeçalho e
   os outros campos já tenham sincronizado via `sync/push` normalmente.

O `sha256` serve para o app saber se um arquivo já foi enviado (dedupe) e
para conferir integridade — o servidor também calcula o hash real do que
recebeu (pela assinatura de bytes, nunca confia no que o cliente declarou).

---

## 8. Sincronização — a peça central do app offline-first

### 8.1 Outbox local (espelha o outbox do servidor, mas é conceito separado)

Toda alteração feita offline (create/update/delete/ação nomeada) grava,
**na mesma transação SQLite**, tanto a mudança no dado local quanto uma
linha na outbox local:

```text
sync_outbox
- operation_id     UUID  -- gerado pelo app, chave de idempotência
- organization_id
- entity_type      -- ver tabela §8.4
- entity_id        -- o mesmo UUID do registro local
- operation_type   -- create | update | delete | ação nomeada (§8.4)
- payload          -- os campos que mudaram, mesmo shape do body REST
- base_version     -- version que o app tinha quando editou (null em create)
- occurred_at
- attempts
- last_error
```

### 8.2 Protocolo (mesmo request/response nos três verbos)

```http
POST /v1/sync/push
{ "operations": [ { "operation_id": "...", "entity_type": "client",
                     "entity_id": "...", "operation_type": "create",
                     "payload": { "name": "..." } }, ... ] }
```

Resposta: um array paralelo, uma entrada por operação enviada:

```json
{ "results": [
  { "operation_id": "...", "entity_type": "client", "entity_id": "...",
    "status": "accepted", "version": 1 }
] }
```

`status` é `accepted` | `rejected` | `conflict`. `rejected` vem com
`error_code` (`BAD_OPERATION_TYPE`, `NOT_FOUND`, `FORBIDDEN`,
`VERSION_REQUIRED`, `UNKNOWN_ENTITY_TYPE`, `INTERNAL`); `conflict` sempre
com `error_code: "VERSION_CONFLICT"`. Reenviar o **mesmo** `operation_id`
depois (ex.: app reiniciou no meio do envio) devolve o resultado já
gravado, sem reaplicar — pode reenviar sem medo de duplicar.

```http
GET /v1/sync/pull?cursor=0&limit=200
```
Devolve as entidades alteradas desde `cursor` (sempre o **estado atual**
completo daquele registro, nunca um diff) + `next_cursor` para continuar.
Chamar em loop até `next_cursor` parar de avançar / vier vazio.

```http
GET /v1/sync/bootstrap?entity_type=client&page=1&size=100
```
Dump completo paginado de um tipo — só para a **primeira sincronização** de
um dispositivo novo (ou reinstalação). Depois disso, use só `pull` a partir
do `cursor` que o bootstrap devolveu.

### 8.3 Conflitos — sempre por `version`, exceto etiqueta

`base_version` desatualizado (alguém mais mudou o registro entre o app
carregar e tentar salvar) vira `conflict`. O app **nunca** deve resolver
isso escondendo o problema — mostrar a versão atual do servidor (via
`pull`) e deixar o usuário decidir se reaplica por cima. Uma transição de
estado inválida (ex.: tentar `complete` numa ordem que não está
`in_progress`, porque o app tinha uma visão desatualizada) também vira
`conflict`/`VERSION_CONFLICT` — mesmo tratamento.

### 8.4 Entidades sincronizáveis (as únicas 7 — não assuma mais nenhuma)

| `entity_type` | `operation_type` aceitos | Observação |
|---|---|---|
| `client` | create, update, delete | — |
| `location` | create, update, delete | `parent_location_id` não muda por sync (reparent é só REST) |
| `equipment` | create, update, delete | — |
| `service_order` | create, update, **start, complete, reopen** | sem `delete` (não existe no domínio) |
| `service_order_part` | create, update, delete | `entity_id` é o da peça; `payload.service_order_id` obrigatório só no `create` |
| `qr_code` | create, **assign, replace, deactivate** | sem `update`/`delete`; ver §9 — não usa `version` de verdade |
| `qr_batch` | *nenhum* (só leitura) | aparece em `pull`/`bootstrap`; criar/reservar/exportar lote é sempre REST |

Tudo que **não** está nessa lista (empresas, tipos de equipamento/serviço,
contatos de cliente/local, modelos de etiqueta, recomendações, fotos,
assinatura, PDF, papéis/permissões) só existe via REST — o app pode até
cachear localmente o que já buscou uma vez, mas **não tem** caminho de
criar/editar isso offline hoje. Se o produto precisar disso no futuro, é
trabalho de backend novo (mesma receita de 4 passos do ADR-0014), não
workaround no app.

---

## 9. Etiquetas offline (spec §11–§12 — leia isto com atenção, é a regra mais fácil de implementar errado)

### 9.1 Preparação (sempre online, feito pelo admin)

```text
Admin cria lote (POST /v1/qr-batches) → exporta (POST .../export)
→ reserva para o técnico/dispositivo (POST .../reserve, com user_id/device_id)
→ técnico sincroniza (o lote e os qr_codes dele aparecem no pull normal)
```

Um código só pode ser **atribuído offline** se já estiver no inventário
local do dispositivo (reservado + sincronizado antes). Escanear um código
que o app não conhece localmente não pode ser confirmado sem conexão —
mostrar "sem conexão para validar este código", nunca inventar uma
confirmação otimista.

### 9.2 Atribuir um código já conhecido, offline

Grava local + outbox, `operation_type: "assign"`:
```json
{ "operation_id": "...", "entity_type": "qr_code", "entity_id": "<id-do-qr-code>",
  "operation_type": "assign", "base_version": 1,
  "payload": { "client_id": "..." } }
```
(`payload` aceita exatamente um entre `client_id`/`location_id`/
`equipment_id`, igual ao corpo REST de `POST /v1/qr-codes/{id}/assign`).
`base_version` é obrigatório no protocolo mas o servidor **não o usa** de
verdade para etiqueta (§9.3) — mande o `version` que você tem, é só forma.

### 9.3 A regra definitiva de conflito (spec §12 — não é negociável)

> **A primeira confirmação do servidor vence.** Sempre.

Não é "o mais recente" nem "o do relógio do dispositivo que chegou
primeiro" — é literalmente qual `push` o servidor processou e aceitou
primeiro. Se dois técnicos offline vincularam o mesmo código físico ao
mesmo tempo (ex.: reimprimiram por engano), quando ambos sincronizarem,
**só um** `assign` vai ser aceito; o outro volta como `conflict`. Quando
isso acontece:

- **Nunca** mesclar clientes/locais/equipamentos.
- **Nunca** transferir a etiqueta automaticamente.
- **Nunca** apagar o que foi cadastrado no registro que perdeu a etiqueta —
  ele continua existindo normalmente, só sem essa etiqueta.
- Mostrar a mensagem definida na spec §12.4 ("Esta etiqueta já está em
  uso... Será necessário substituir a etiqueta física...") e criar uma
  pendência visível (tela inicial + no próprio registro) até o usuário
  resolver com `replace` (§9.4).

### 9.4 Substituir / desativar

```json
{ "operation_type": "replace", "payload": { "new_code_id": "<opcional>" } }
{ "operation_type": "deactivate" }
```
`replace` sem `new_code_id` faz o servidor gerar um código novo sozinho —
**offline isso não funciona** (o texto do código de ~80 bits só é gerado no
servidor, por desenho — ver ADR-0019). Para substituir offline, o técnico
precisa ter um código sobressalente **já reservado no dispositivo**
(mesmo mecanismo do lote, §9.1) e informar `new_code_id`. Depois de um
`replace` aceito, o código **novo** aparece no próximo `pull` como
qualquer entidade alterada — não vem na resposta do próprio `push`.

### 9.5 Criar etiqueta nova (não a partir de um lote)

`operation_type: "create"` com `entity_id` gerado pelo app — funciona
offline (o UUID é só a chave primária), mas o texto do código público
(o que fica impresso/escaneável) **é sempre gerado pelo servidor**
(ADR-0019), então uma etiqueta "criada" offline sem código pré-existente
fica sem `public_code` até sincronizar — não é um QR Code utilizável antes
disso. Na prática, esse caminho serve para o caso raro de "vincular sem
ter nenhum código físico ainda"; o fluxo comum de campo é sempre §9.1–9.2.

---

## 10. PDF do laudo — duas cópias, por decisão de design (ADR-0018)

O `worker` já gera o PDF oficial (`internal/pdfjobs`) quando a ordem
sincroniza — isso **não muda**. Mas para o técnico sair de campo com o
laudo em mãos mesmo sem internet (fotos, assinatura e diagnóstico já
capturados no aparelho), **o app precisa montar seu próprio PDF
localmente** (Dart, ex. pacotes `pdf`/`printing`) a partir dos dados que já
estão no dispositivo. São dois artefatos com propósitos diferentes — o do
servidor é a cópia canônica (acessível de qualquer lugar depois); o do
app é o que o técnico entrega na hora. Nenhuma sincronia entre os dois é
necessária além dos dados de origem já estarem consistentes.

---

## 11. Ordem sugerida de implementação

Como o backend inteiro já existe, a ordem não precisa esperar nenhuma
entrega de servidor — pode seguir puramente pela complexidade do cliente:

1. **Estrutura + login + `/v1/me`** — sem persistência local ainda, só
   confirma que o app fala com a API.
2. **SQLite/Drift + sessão offline** — banco por organização, PIN/
   biometria, TTL de 7 dias.
3. **Bootstrap + pull, sem outbox ainda** (app só-leitura) — cadastros
   principais (clientes/locais/equipamentos) na tela, vindos do banco
   local.
4. **Outbox + push** para as mesmas 3 entidades — primeiro create/update
   simples, depois delete.
5. **Ordens de serviço** — cabeçalho + peças via sync; fotos/assinatura via
   fila de upload (§7); PDF local (§10).
6. **Etiquetas** — leitura de lote/código via sync; `assign`/`replace`/
   `deactivate` offline (§9) por último, é a parte com mais regra de
   negócio fina.
7. **Tudo que é REST-only** (empresas, tipos, contatos, modelos de
   etiqueta, recomendações) — pode entrar em paralelo a qualquer momento,
   já que não depende de sync nem tem regra offline.

---

## 12. Decisões que ainda são do time Flutter (não do backend)

Da spec §30, ainda em aberto e sem impacto no servidor:

- biblioteca de criptografia do SQLite compatível com todas as plataformas-
  alvo;
- formato exato de captura de assinatura (o servidor só exige PNG na
  validação de upload);
- estratégia de retomada de upload (qual lib HTTP, chunking ou não);
- design de tela para a pendência de "substituição de etiqueta necessária".

---

## 13. Referências

| Assunto | Onde |
|---|---|
| Contrato exato de cada endpoint | `openapi/openapi.yaml` |
| Protocolo de sync (decisões e porquês) | ADR-0014, ADR-0018, ADR-0019 |
| Regra de conflito de etiqueta (produto) | spec §11, §12 |
| Autenticação híbrida | spec §16, ADR-0004, ADR-0007, ADR-0008 |
| Permissões por campo | spec §17, ADR-0009, ADR-0010 |
| Banco local / sessão offline | spec §18 |
| Upload de anexo (validação de bytes) | ADR-0012, `internal/platform/httpx/upload.go` |
| PDF local vs. PDF do servidor | ADR-0018 §"PDF: continua fora do sync" |
| Layouts de etiqueta impressa | ADR-0016 (A4/compacto), ADR-0022 (térmica) |
| Estado geral do backend | `docs/progresso.md` |
