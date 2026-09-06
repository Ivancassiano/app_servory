# Progresso

Arquivo de acompanhamento entre sessões, compartilhado entre os dois
repositórios do produto: `auth_servory` (backend, `~/go/src/auth_servory`) e
`app_servory` (app Flutter, este repositório). Para retomar o backend:
`claude --continue` dentro de `/Users/ivancassiano/go/src/auth_servory`.

## `app_servory` — `feature/service-orders`: PDF do laudo (cópia de campo) ✅

Fecha o item §10 do `GUIA-FLUTTER.md` / ADR-0018 ("PDF: continua fora do
sync"). O `worker` continua gerando a via canônica no servidor quando a
ordem sincroniza; esta fatia é só a **cópia de campo** que o técnico gera e
entrega na hora, montada 100% do que já está no dispositivo (banco local +
arquivos de anexo) — nada aqui toca a rede.

- **`pdf` + `printing`**: `buildServiceOrderPdf(ServiceOrderReportData)`
  (`service_order_pdf.dart`) é função pura (bytes de entrada → `Uint8List`),
  sem I/O nem Riverpod, testável direto. `ServiceOrderReportScreen` usa o
  `PdfPreview` do `printing` (pré-visualização + compartilhar + imprimir; o
  compartilhar usa a folha nativa do SO e funciona offline). Rota
  `/service-orders/:id/report`, botão na `ServiceOrderDetailScreen`.
- **`serviceOrderReportDataProvider`** (`FutureProvider.family`, não Stream —
  o laudo é um retrato do momento do toque, não algo ao vivo): junta ordem
  + cliente + local + equipamento + peças do banco local e lê fotos/
  assinatura **do disco**, não da URL assinada do servidor. Nome do técnico/
  organização vêm de `identityProvider` *só se já estiver em cache* nesta
  sessão (`.asData?.value`) — login feito offline simplesmente omite a
  linha, sem disparar rede.
- **Anexo agora em subpasta por tipo** (`attachments/{id}/photos/` e
  `/signature/`): antes tudo caía em `attachments/{id}/` com nome UUID. Como
  a fila de upload apaga a linha (mas não o arquivo) depois de enviar, o
  gerador de PDF precisava classificar cada arquivo só pelo caminho — a
  subpasta deixa a pasta auto-descritiva. `caption`/`photo_kind` só entram
  no PDF enquanto o item ainda está na fila (metadado some junto com a
  linha); "Substituir" assinatura usa o arquivo mais recente da pasta.
- **Rodapé** avisa quando `hasPendingUploads` — deixa explícito que a via
  oficial no servidor ainda vai divergir desta até sincronizar.
- **Fontes**: as embutidas do `pdf` (Helvetica) cobrem Latin-1, o que basta
  pro português — só o travessão `—` (U+2014) não renderiza, então o
  gerador usa hífen/`·`. Embutir uma TTF Unicode de verdade fica como
  melhoria de tipografia, não bloqueia.
- 33 testes (era 30): 3 novos em `service_order_pdf_test.dart` (PDF válido
  com dados mínimos; com peças/fotos/assinatura; ordem vazia sem estourar).
  Sem teste do provider (depende de `path_provider`/plataforma — mesmo
  critério das fatias anteriores: cobertura real vem da verificação ao vivo).
- **Ainda não verificado ao vivo** no emulador/simulador (build Android +
  iOS-simulador compilando OK). Fluxo a exercer: capturar foto+assinatura
  offline → "Gerar PDF" → conferir preview e compartilhar.

### Próximo (app)

- Verificação ao vivo do PDF (capturar anexos offline → gerar → compartilhar).
- Criar (não só editar) location/equipment — precisa de seletor de
  cliente/local/tipo na UI.
- Formulário de ordem: campos REST-only (tipo de ordem, empresa emissora,
  técnico designado, `scheduled_for`).
- Etiquetas/QR Code (spec §8–§12) — nada implementado no app ainda.
- Empresas e Pessoa (`companies`/`people`) — emitente do laudo.
- l10n via ARB quando houver material de tradução real.

## `app_servory` — `feature/service-orders`: fotos e assinatura via fila de
## upload offline ✅

Fecha a segunda metade do item 5 do `GUIA-FLUTTER.md` §11 (a primeira,
cabeçalho+peças via sync, é a entrega anterior nesta mesma branch). PDF
local (§10) fica pra próxima fatia — decisão já tomada de não misturar
upload binário com geração de PDF na mesma entrega.

- **Fila de upload local** (`UploadQueue`, `schemaVersion` 2→3): captura de
  foto (`image_picker`, câmera **ou** galeria + classificação
  `before/after/other` + legenda) e assinatura (pacote `signature`, canvas
  → PNG) salvam o arquivo local na hora — mesmo offline — e só enfileiram o
  envio. `UploadQueueController` (grava arquivo em
  `ApplicationDocuments/attachments/{serviceOrderId}/` + SHA-256 via
  `crypto`) + `UploadQueueRunner.drain()` (REST puro,
  `multipart/form-data` — fotos/assinatura **não** fazem parte do
  protocolo de sync, GUIA-FLUTTER §8.4) + `AttachmentsApi`. Reenvio é do
  arquivo inteiro (decisão já tomada com o usuário, sem retomada por
  chunks).
- **UI**: seções "Fotos" (grade com já enviadas + pendentes) e "Assinatura"
  (slot único) na `ServiceOrderDetailScreen`; puxar-pra-atualizar drena a
  fila além de sincronizar as entidades normais.
- **Achado real 1, corrigido**: depois de um upload bem-sucedido, a seção
  ficava "presa" no estado de antes (nem mostrava pendente, nem mostrava
  enviada) até a tela recarregar por outro motivo — `orderPhotosProvider`/
  `orderSignatureProvider` (REST, `FutureProvider`) não eram invalidados
  depois do `drain()` remover o item da fila local. Corrigido invalidando
  o provider certo (por `kind`) dentro do próprio `UploadQueueRunner.drain()`
  — exigiu extrair `attachmentsApiProvider` pro próprio arquivo
  (`attachments_api_provider.dart`) pra evitar import circular entre
  `upload_queue_provider.dart` e `service_order_attachments_provider.dart`.
- **Achado real 2, corrigido**: `Image.network` sem `errorBuilder` deixava
  o texto do erro (`SocketException: ...`) sobrepor o layout e causar
  overflow visual quando a URL de download falhava — agora mostra um
  ícone de imagem quebrada, sem estourar a tela, independente da causa do
  erro de rede.
- **Confirmado, não é bug do app**: a regra de negócio "ordem precisa estar
  editável" (`draft`/`open`/`in_progress`) também vale pra fotos/assinatura,
  igual já valia pra peças — testado deixando a ordem `completed` de
  propósito, viu o erro `NOT_EDITABLE` aparecer corretamente na fila
  (mensagem de erro exibida por item pendente), reabriu a ordem e o
  reenvio funcionou.
- **Limitação de ambiente encontrada, não é bug do app nem do backend**:
  neste AVD específico (`Pixel9`, API 35), `image_picker` não conseguiu
  completar nem câmera nem galeria (o app volta pro launcher sem erro
  visível) — bounds/toques confirmados corretos via `uiautomator dump`, e
  o intent `android.media.action.IMAGE_CAPTURE` funciona quando disparado
  direto por `adb shell am start`, então não é falta de app instalado.
  Verificação ao vivo do envio em si foi feita pelo fluxo de assinatura
  (canvas interno, sem depender de nenhuma Activity externa do Android) —
  cobre a mesma fila/API/backend que fotos usam. Adicionado
  `<queries>` para `IMAGE_CAPTURE` no `AndroidManifest.xml` como boa
  prática (não resolveu por si só) — se persistir num dispositivo real,
  investigar como item separado, não bloqueia esta entrega.
- **Outro achado, é do backend/infra, não deste app**: a URL assinada que o
  MinIO devolve usa o hostname interno do Docker (`minio`), que não é
  resolvível fora da rede Docker — então baixar a foto/assinatura pelo
  emulador falha com `Failed host lookup: 'minio'`. Confirmado ao vivo:
  upload funcionou (bytes/hash certos no Postgres), só o download pela URL
  assinada que não resolve neste ambiente. Registrado pro usuário; não é
  algo pra corrigir no app (o app só usa a URL que o servidor manda) —
  ajuste seria no `S3_ENDPOINT`/config do MinIO no `docker-compose` do
  `auth_servory`.
- 30 testes automatizados (era 29): 1 novo em `app_database_test.dart`
  (CRUD da `UploadQueue`). Sem teste de API/controller isolado — mesmo
  padrão já estabelecido (cobertura real vem da verificação ao vivo,
  captura de câmera/canvas não vale a pena mockar em unidade).

### Próximo (app)

- PDF local (§10) — usa os arquivos já salvos por esta fatia.
- Investigar `image_picker` em dispositivo real (o problema pareceu ser
  específico deste AVD).
- Criar (não só editar) location/equipment — precisa de seletor de
  cliente/local/tipo na UI.
- Formulário de ordem: campos que dependem de dado REST-only (tipo de
  ordem, empresa emissora, técnico designado, `scheduled_for`).
- Etiquetas/QR Code (spec §8–§12) — nada implementado no app ainda.
- Empresas e Pessoa (`companies`/`people`) — usados como emitente do laudo.
- l10n via ARB quando houver material de tradução real.

## `app_servory` — `feature/service-orders`: Ordens de Serviço — cabeçalho
## + peças via sync ✅

Nova branch (a partir de `feature/offline-storage`, que segue não mergeada em
`main`). Fatia deliberadamente recortada do item 5 do `GUIA-FLUTTER.md` §11:
só cabeçalho da ordem (`create`/`update`/`start`/`complete`/`reopen`) + peças
(`create`/`update`/`delete`) via sync — fotos/assinatura (fila de upload
binário) e PDF local ficam para a próxima fatia, decisão tomada com o usuário
para não misturar protocolo JSON de sync com upload multipart na mesma
entrega.

- **Banco local**: `LocalServiceOrders`/`LocalServiceOrderParts` (mesmo molde
  `_SyncColumns`; `unit_cost`/`unit_price` nullable — sensíveis, mesmo
  tratamento de `equipment.cost`). Primeira migração real do schema
  (`schemaVersion` 1→2, `MigrationStrategy.onUpgrade` só cria as 2 tabelas
  novas, preserva dado local já sincronizado).
- **`SyncEngine`**: `service_order`/`service_order_part` somados a
  `_readEntityTypes`; `_upsert`/`_softDelete`/`_markSynced`/
  `_markPushFailed` ganham os `case` das duas entidades, mesmo padrão já
  corrigido na entrega anterior para location/equipment.
- **UI**: `ServiceOrderListScreen` (join com cliente pra evitar N+1) +
  `ServiceOrderDetailScreen` (sentinela `'new'`; criar exige cliente,
  local/equipamento opcionais filtrados em cascata a partir do que já está
  sincronizado localmente; editar mostra cliente só-leitura — imutável no
  protocolo — e os botões de transição condicionais ao `status` atual) +
  seção de peças (bottom sheet reusado para adicionar/editar, exclusão
  inline). `ServiceOrderEditController`/`ServiceOrderPartController` no
  mesmo molde local-primeiro dos demais.
- **Achado real 1, corrigido**: `SyncRunner.runSync()` chamava `pull()`
  **antes** de `pushPending()`. Numa sequência rápida de ações na mesma
  ordem (`Iniciar` → `Concluir`), o `push` do `Iniciar` gera no servidor um
  evento de outbox que só é buscado no próximo `pull` — como esse próximo
  `pull` roda *antes* do `push` do `Concluir`, ele aplicava o estado
  "velho" (`in_progress`) por cima da escrita local otimista mais nova
  (`completed`) que ainda estava só na outbox; o `push` seguinte confirmava
  a `version` mas não corrigia o `status`, deixando o app mostrando um
  estado diferente do servidor até o usuário puxar pra atualizar manualmente.
  Corrigido invertendo a ordem (drena a outbox primeiro, só depois puxa) —
  `sync_provider.dart`. Coberto por teste novo (`sync_provider_test.dart`,
  `SyncEngine` mockado via mocktail, confere a ordem das chamadas).
- **Achado real 2, corrigido**: `ServiceOrderDetailScreen` zerava
  `_locationId`/`_equipmentId` permanentemente quando a lista filtrada de
  locais/equipamentos ainda não tinha carregado (1ª renderização depois de
  abrir o app) — o valor voltando do servidor continuava correto, só a
  tela local "esquecia" a seleção pra sempre (nada re-seedava depois, o
  `_seeded` guard já tinha passado). Corrigido com uma guarda de loading
  (`!locationsAsync.hasValue`) antes de montar o formulário de edição +
  trocando a mutação direta por um valor de exibição derivado
  (`displayLocationId`/`displayEquipmentId`) que nunca sobrescreve o estado
  de verdade.
- Ambos achados vieram de teste ao vivo no emulador (não de teste
  automatizado) — cabeçalho + 1 peça criados pela UI, `Iniciar`→`Concluir`
  em sequência expôs o 1º bug, reabrir o app e reentrar na ordem expôs o 2º.
  Depois de corrigidos: ciclo completo `Aberta`→`Iniciar`→`Concluir`→
  `Reabrir`→`Concluir` de novo, cada transição confirmada por `psql` direto
  no Postgres (status/version bateram em tempo real, sem precisar de pull
  manual).
- 29 testes automatizados (era 24): 3 novos em `sync_engine_test.dart`
  (bootstrap de `service_order`/`service_order_part`, push de ação nomeada +
  create/update/delete de peça), 1 em `app_database_test.dart`, 2 novos em
  `sync_provider_test.dart` (ordem push→pull). Todos verdes.
- **Fora do escopo** (registrado, não é dívida esquecida): fotos/assinatura
  via fila de upload, PDF local (ADR-0018 §10); `scheduled_for`/
  `service_order_type_id`/`company_id`/`assigned_user_id` no formulário —
  dependem de entidades REST-only (tipos de ordem, empresas, membros da
  org) que o app ainda não busca/cacheia.

### Próximo (app)

- Fotos/assinatura de ordem via fila de upload (§7) + PDF local (§10).
- Criar (não só editar) location/equipment — precisa de seletor de
  cliente/local/tipo na UI.
- Formulário de ordem: campos que dependem de dado REST-only (tipo de
  ordem, empresa emissora, técnico designado, `scheduled_for`).
- Etiquetas/QR Code (spec §8–§12) — nada implementado no app ainda.
- Empresas e Pessoa (`companies`/`people`) — usados como emitente do laudo.
- l10n via ARB quando houver material de tradução real.

## `app_servory` — `feature/offline-storage`: outbox/push em location e
## equipment (fechando a paridade de escrita das 3 entidades) ✅

Fatia pequena e mecânica, fechando o item deixado pendente na entrega
anterior. Só edição (criar exige seletor de cliente/pai ou de local/tipo —
UI que ainda não existe; editar um registro já sincronizado não precisa).

- **Achado real, corrigido**: `SyncEngine.pushPending()` estava
  hardcoded pra só escrever de volta em `localClients`, mesmo recebendo
  resultado de push de `location`/`equipment` — o resultado seria
  descartado silenciosamente pras outras duas. Generalizado com
  `_markSynced`/`_markPushFailed` despachando pelo `entityType`, igual o
  `_upsert`/`_softDelete` já faziam. Achado *antes* de escrever a UI, ao
  planejar a fatia — coberto por teste novo em `sync_engine_test.dart`
  que grava outbox de `location`+`equipment` junto e confirma que cada um
  atualiza a tabela certa.
- `LocationEditController`/`EquipmentEditController` (só `update`, mesmo
  padrão local-primeiro do `ClientEditController`) + `LocationDetailScreen`/
  `EquipmentDetailScreen` (formulário de edição) + `locationByIdProvider`/
  `equipmentByIdProvider`. Campos sensíveis (`serial_number`, `cost`) ficam
  de fora do formulário de equipamento — o app não verifica permissão de
  escrita por campo ainda.
- **Verificado ao vivo**: criei um local ("Cozinha Central") e um
  equipamento via `curl` direto no backend (para ter dado real pra
  editar, já que criar pela UI ainda não existe pras duas), sincronizei no
  app, editei as observações do local pela UI do emulador, salvou sem
  ícone de pendência, e confirmei por `curl` que `notes: "Revisada"` e
  `version: 2` chegaram no servidor. `equipment` usa exatamente o mesmo
  código (`_markSynced`/`_markPushFailed`) e está coberto pelo teste
  automatizado; não repeti o mesmo passo a passo manual pra não gastar
  tempo repetindo uma verificação que já é redundante com o teste.
- 24 testes automatizados (era 23), todos verdes.

### Próximo (app)

- Ordens de serviço — a próxima fatia funcional de peso (cabeçalho, peças,
  fotos/assinatura via fila de upload, PDF local, GUIA-FLUTTER §7/§10).
- Criar (não só editar) location/equipment — precisa de seletor de
  cliente/local/tipo na UI.
- l10n via ARB quando houver material de tradução real.

## `app_servory` — branch `feature/offline-storage`: banco local + sessão
## offline + sync (client/location/equipment) ✅

Segunda entrega do app, sobre a fundação (login) já em `main`. Banco local
criptografado, sessão offline por biometria/PIN do aparelho, bootstrap/pull
somente-leitura para `location`/`equipment`, e outbox/push completo (create +
update) para `client` — provado ponta a ponta contra o backend real.

- **Achado real, resolvido antes de implementar**: o pacote recomendado no
  início (`sqlcipher_flutter_libs`) está obsoleto — a partir do `sqlite3` v3
  o próprio mantenedor do drift descontinuou esse caminho a favor de um
  sistema de hooks de build (`hooks: user_defines: sqlite3: source:
  sqlite3mc`, SQLite3 Multiple Ciphers). Validado com um spike isolado antes
  de construir o resto: teste real gravando um arquivo `.sqlite` com `PRAGMA
  key`, confirmando `PRAGMA cipher; -> chacha20` e que o conteúdo não
  aparece em texto claro no disco — rodado tanto no host (`flutter test`)
  quanto de verdade no emulador Android (`flutter run`), antes de comprometer
  a arquitetura da fatia inteira a essa dependência.
- **Banco local** (`lib/core/db/`): `AppDatabase` (Drift) com `LocalClients`,
  `LocalLocations`, `LocalEquipments` (espelham os schemas do OpenAPI, campos
  mascaráveis nullable — ausência = sem permissão, não vazio),
  `SyncOutbox`, `LocalSyncState` (cursor por organização). Conexão
  condicional (`connection.dart` exporta `connection_native.dart` via
  `dart.library.io`, ou `connection_web.dart` — um stub que nunca roda,
  já que o Chrome não usa nada disto) — arquivo
  `servory-{organization_id}.sqlite` em `getApplicationSupportDirectory()`,
  chave AES de 256 bits gerada uma vez por `DbKeyStore` e guardada no
  Keychain/Keystore via `SecureStore` (nunca sai do aparelho).
- **Sincronização** (`lib/features/sync/`): `SyncApi` (push/pull/bootstrap
  tipados) + `SyncEngine` (bootstrap pagina os 3 tipos; pull aplica
  update/delete e avança o cursor até estabilizar; pushPending drena a
  outbox — `accepted` grava version+synced, `conflict` marca e drena,
  erro transitório mantém pra retry). `SyncRunner` (Riverpod) dispara
  bootstrap no primeiro login da organização e pull/push depois disso.
- **Sessão offline** (spec §18.3): `SessionController` grava
  `lastOnlineValidationAt` a cada login/refresh; `AppLockController`
  re-trava ao ir para segundo plano; `AppRouter` ganha `/unlock` (biometria
  OU PIN/padrão do aparelho via `local_auth`, `biometricOnly: false` — cobre
  a spec sem precisar construir um PIN próprio do app) e
  `/offline-expired` (offline + mais de 7 dias sem confirmar com o
  servidor — bloqueia sem apagar dado local). Lógica de redirect extraída
  em `decideRedirect` (função pura, testável sem GoRouter/widget de
  verdade).
- **UI mínima**: `ClientListScreen`/`ClientDetailScreen` (lista + criar/
  editar, grava local e tenta sincronizar na hora — outbox garante retry se
  offline) e `LocationListScreen`/`EquipmentListScreen` (só leitura).
  `HomeScreen` ganha os 3 atalhos.
- **Testes** (23, todos verdes): schema Drift (`NativeDatabase.memory()`),
  `SyncEngine` (bootstrap/pull/push com `SyncApi` fake), lógica de redirect
  do router (7 casos), suíte anterior (23) intacta.
- **Verificado ao vivo no emulador Android** (não só testes automatizados):
  login real → bootstrap rodando (listas vazias sem erro) → criado um
  cliente pela UI → apareceu sem ícone de pendência (sincronizou na hora) →
  confirmado por `curl` direto no `servicelog-api` que o registro existe no
  servidor com `version: 1`. Depois: wifi/dados desligados
  (`adb shell svc wifi disable` / `svc data disable`) → app relançado →
  tela de "Você está offline" apareceu corretamente e, como este emulador
  não tem biometria/PIN configurado, mostrou a mensagem de "conecte-se"
  (branch da spec §18.3 para aparelho sem lock configurado) em vez de tentar
  um `local_auth.authenticate` que falharia — religar a rede voltou pra Home
  sozinho, sem reabrir o app.
  - Achado à parte, sem relação com o código do app: o emulador ficou
    reabrindo um diálogo do sistema Android ("Try out your stylus") por
    cima da tela durante os testes de digitação — atrapalhou a automação via
    `adb shell input text`, não é um bug do ServiceLog. Contornado
    desligando via `adb shell settings put secure stylus_handwriting_enabled 0`
    (mudança só no emulador local, não no app).
- **Fora do escopo desta entrega** (registrado no plano, não é dívida
  esquecida): outbox/push para `location`/`equipment` (só leitura por
  ora — mesma receita de `client` quando entrar); cache de
  `equipment_type` (REST-only); qualquer coisa no Chrome (decisão já
  tomada: sempre-online).

### Próximo (app)

- Ligar outbox/push em `location`/`equipment` no mesmo molde de `client`.
- Fotos/assinatura de ordem de serviço (fila de upload, GUIA-FLUTTER §7).
- l10n via ARB quando houver material de tradução real.

## `app_servory` — fundação do app Flutter (iOS, Android, Chrome) ✅

Primeira entrega do app (repo antes só com documentação). Login real, `/v1/me`
na Home, rodando nos 3 alvos. Sem cadastros, banco local nem sincronização
ainda — próxima entrega.

- **Decisão confirmada com o usuário**: Chrome roda **sempre online** — sem
  SQLite/Drift nem sessão offline por PIN no navegador; o app web chama a API
  a cada tela. Todo o esforço de offline-first (banco criptografado, outbox,
  sync, spec §18–§19) fica restrito a iOS/Android nas entregas seguintes.
- **Achado**: `auth-api`/`servicelog-api` não tinham CORS — bloqueava
  qualquer chamada do Flutter Web (host/porta próprios). Corrigido no
  `auth_servory` (não neste repo): `internal/platform/httpx/cors.go` (novo
  middleware, preflight + `Access-Control-Allow-*`), `CORS_ALLOWED_ORIGINS`
  em `config.go`/`.env.example` (default `*` — seguro porque a auth é só via
  `Authorization: Bearer`, sem cookie de sessão), ligado em
  `cmd/{auth-api,servicelog-api}/main.go`. Testado ao vivo (preflight real
  via curl) e com `internal/platform/httpx/cors_test.go`.
- **Scaffold**: `flutter create --platforms=ios,android,web --org com.servory
  --project-name servory .` — projeto nasce na raiz deste repo, convivendo
  com `docs/` e a spec.
- **Dependências**: `flutter_riverpod` (estado/DI, sem codegen nesta fase),
  `go_router` (roteamento + guarda de sessão), `dio` (HTTP),
  `flutter_secure_storage` (sessão — Keychain/Keystore no mobile,
  IndexedDB+WebCrypto no Chrome; não é o banco local criptografado da spec
  §18, que só chega com Drift na entrega mobile), `uuid` (device id), dev:
  `mocktail`.
- **Estrutura** (`lib/core/*` genérico + `lib/features/{auth,me}/{data,
  application,presentation}`):
  - `core/config/app_config.dart` — base URLs por `--dart-define` com default
    por plataforma (`10.0.2.2` no Android, `localhost` no resto) via
    `defaultTargetPlatform`/`kIsWeb` (não `dart:io Platform`, que não
    compila para Web).
  - `core/network/api_client.dart` + `auth_interceptor.dart` — dois `Dio`
    (`authDio` :8080 sem interceptor, `businessDio` :8081 com
    `AuthInterceptor`): injeta `Authorization: Bearer`, em qualquer 401
    dispara refresh (lock único — chamadas concorrentes compartilham o mesmo
    refresh em voo) e repete a chamada original **pelo mesmo `businessDio`**
    (não um `Dio` avulso — reusa adapter/interceptors/config; importante
    para produção e para testar com adapter fake). Falha de refresh limpa a
    sessão e avisa via `SessionExpiredPort` (`core/providers.dart` — quebra a
    dependência circular `ApiClient` ↔ `SessionController`).
  - `core/network/api_exception.dart` — parseia o envelope
    `{error:{code,message,...}}` e trata sempre por `code` (GUIA-FLUTTER.md
    §6), com dicionário PT dos códigos conhecidos + fallback genérico.
  - `core/storage/secure_store.dart` — tokens + `device.id` persistido uma
    vez por instalação (nunca regenerado a cada login, spec §16.3).
  - `core/router/app_router.dart` — `GoRouter` reconstruído a cada mudança de
    `SessionState` (só 2 rotas por ora, mais simples que um
    `ChangeNotifier` à parte); splash enquanto restaura a sessão do
    armazenamento seguro.
  - `features/auth` — `AuthApi` (`login`/`logout`), `SessionController`
    (`Notifier<SessionState>` — `unknown/unauthenticated/authenticating/
    authenticated`; **bug real corrigido**: `_restore()`/`login()`/`logout()`
    guardam `ref.mounted` antes de setar `state` depois de um `await` — sem
    isso, um container/provider descartado no meio da restauração assíncrona
    derrubava com "Cannot use the Ref ... after it has been disposed",
    achado pelos próprios testes), `LoginScreen`.
  - `features/me` — `MeApi` (`GET /v1/me`, `GET /v1/me/permissions`),
    `HomeScreen` (identidade + organização + logout).
  - Sem l10n via ARB ainda (spec §25 pede pt/it/en/es no não-funcional) —
    strings PT hardcoded por ora; registrado como pendência, não bloqueia a
    fundação.
- **Testes** (10, todos verdes): `auth_interceptor_test.dart` (401 → refresh
  → repete a chamada original; refresh concorrente dedupicado; falha de
  refresh limpa sessão) via um `HttpClientAdapter` fake anexado ao próprio
  `Dio` (sem pacote de mock HTTP extra); `session_controller_test.dart`
  (restaura sem sessão, login ok, login com erro propaga `ApiException`,
  `SessionExpiredPort` força logout) via `ProviderContainer` com
  `authApiProvider`/`secureStoreProvider` sobrescritos (`mocktail`);
  `login_screen_test.dart` (campos+validação, não chama login com form
  inválido, chama com dados corretos). `flutter analyze` limpo (só 3 infos
  de estilo).
- **Verificado ao vivo**: criado admin descartável
  (`qa@servory.local`/`ServiceLog QA`) via `auth-api bootstrap` contra o
  Docker local; login confirmado por `curl` direto no `auth-api` antes de
  testar pela UI. `flutter run -d chrome` serve `index.html`/`main.dart.js`
  corretamente (confirmado por `curl`; a extensão claude-in-chrome não
  estava conectada nesta sessão para um passo a passo visual automatizado —
  fica para o usuário abrir `http://localhost:5959` e conferir). App real
  instalado e rodando no emulador Android (`Pixel9`, API 35) e tela de login
  renderizada pixel a pixel igual ao design; tentativas de preencher o
  formulário via `adb shell input text` esbarraram no autofill nativo do
  Android (que os campos declaram de propósito via `autofillHints`, spec
  correta para um usuário real) — não é um problema do app; a cobertura real
  do fluxo de submit já vem dos testes de widget (`tester.enterText`, API
  oficial do Flutter, sem essa fricção).
  - **Achado real 1** (corrigido): `flutter_secure_storage` exige
    `compileSdk 37`; o scaffold padrão do `flutter create` gerava `compileSdk
    = flutter.compileSdkVersion` (36). `android/app/build.gradle.kts` fixado
    para `compileSdk = 37`.
  - **Achado real 2** (ambiente local, não é código): o Xcode 26.6 desta
    máquina só tem os simuladores iOS 26.0/26.2 instalados, mas o SDK de
    build é o 26.5 — `xcodebuild` não resolve nenhum destino de simulador
    (nem um genérico `iOS Simulator`), incluindo `flutter build ios
    --no-codesign --simulator`. Fix é local: Xcode → Settings → Components →
    instalar o runtime do iOS Simulator 26.5. Não bloqueia o código entregue.
- **Documentação**: `README.md` novo (raiz de `app_servory`) — como rodar
  contra o backend local nos 3 alvos, `--dart-define`, criação do usuário de
  teste, nota sobre CORS.

### Próximo (app)

- SQLite/Drift + outbox + sessão offline por PIN/biometria — só iOS/Android
  (GUIA-FLUTTER.md §5, §8, §11 item 2).
- Bootstrap/pull somente-leitura dos cadastros principais (clientes, locais,
  equipamentos).
- l10n via ARB quando houver material de tradução real.

## Branch atual: `feature/servicelog-cadastros` — backend de negócio (Fase 3, Cadastros)

Nasceu de `feature/servicelog-api` (já mergeada na `main`).

Nasceu de `feature/auth-foundation` (M0–M6, fundação de segurança completa).
Guia de referência: `docs/GUIA-BACKEND-NEGOCIO.md`.

### Feito nesta branch

- **Separação auth ↔ negócio** ✅ — `cmd/servicelog-api` criado.
  - `auth-api` (:8080) → só `/v1/auth/*`; detém a chave PRIVADA do JWT.
  - `servicelog-api` (:8081) → `/v1/me`, `/v1/organization`, `/v1/users`,
    `/v1/roles`, `/v1/permissions`, `/v1/audit` (+ negócio); verifica com a chave
    PÚBLICA (`tokens.LoadVerifyKeySet`), reusa `iam.Service.Authenticator`.
  - `iam.Service.Routes` dividido: `Routes` (auth) + `IdentityRoutes` (`/me`).
  - Teste de drift do OpenAPI por serviço (`internal/testsupport/apidoc`,
    `cmd/*/routes_test.go`) — cada um valida só as rotas que "possui".
  - compose dev/prod com os dois serviços; proxy roteia `/v1/auth/*` → 8080,
    resto → 8081.
  - Smoke ok: token emitido pelo auth-api é verificado pelo servicelog-api.
  - Hardening dos papéis de banco (`servory_business`/`servory_worker`)
    concluído — ver `ADR-0015` e a entrada "Hardening" abaixo. Volume de
    chaves JWT (só `.pub.pem` para `servicelog-api`/`worker`) continua
    fora do escopo.

- **`internal/clients`** ✅ — 1ª entidade de negócio ponta a ponta (molde do guia §4):
  - `migrations/00008_clients.sql` (schema §7.3 + 7 colunas padrão + `clients_org_idx`
    + trigram no nome + `set_row_defaults` + RLS `ENABLE`/`FORCE` + `audit_row_history`).
    Permissões já vinham do seed 00006.
  - `internal/db/queries/clients.sql` (get/list c/ busca+paginação/count/create/
    update c/ trava otimista/soft delete) → sqlc.
  - `internal/clients/{clients.go,http.go}`: `List/Get/Create/Update/Delete` via
    `AuthorizeWith` (checa `client.*` + passa `Effective` p/ máscara de campo).
    Campos controlados: `name`, `phone`, `internal_notes` (`FilterReadable` na
    saída, `UnauthorizedWrites` → 422 na entrada). Eventos `client.created/updated/deleted`.
  - Montado em `servicelog-api` → `/v1/clients`.
  - `permissions.Resolver.AuthorizeWith` — variante que entrega o `Effective` ao callback.
  - Testes: `internal/clients/clients_test.go` (CRUD, trava otimista, isolamento
    entre orgs §26.1, máscara de leitura e de escrita §26.2, forbidden). openapi
    + drift atualizados. `app.clients` no `testdb.truncateSQL`.
  - Smoke ponta a ponta pelo servicelog-api: CRUD + busca + 409 + auditoria + 404 pós-delete.

- **`internal/locations`** ✅ (commit `0499867`) — hierarquia Cliente > Local (spec §2, §7.4).
  - `migrations/00009_locations.sql`: `app.locations` + FK composta
    `(organization_id, client_id) → app.clients` (exige `UNIQUE (organization_id, id)`
    em `clients`, spec §14.2), índices, `set_row_defaults`, RLS, `audit_row_history`.
  - `internal/db/queries/locations.sql` (list filtrável por `client_id` via `sqlc.narg`).
  - `internal/locations/{locations.go,http.go}`: `View` tipada (sem máscara de campo),
    `Create` valida que o cliente existe na org (`ErrClientNotFound` → 422). Rotas `/v1/locations`.
  - Testes: CRUD + filtro por cliente, isolamento, `ErrClientNotFound` cross-org, forbidden.

- **`internal/equipmenttypes`** ✅ — dado de referência por org (spec §6).
  - `migrations/00010_equipment_types.sql`: novas permissões `equipment_type.*` no
    catálogo + templates (admin=tudo, viewer/technician=read) + **backfill** dos
    perfis `is_system` já materializados + bump de `permission_version`.
    `app.equipment_types` (`UNIQUE (organization_id, id)` p/ FK composta;
    índice único `(organization_id, lower(name)) WHERE deleted_at IS NULL`), RLS, auditoria.
  - `internal/db/queries/equipment_types.sql` + `internal/equipmenttypes/{equipmenttypes.go,http.go}`:
    `View` tipada, `List/Get/Create/Update/Delete` via `Authorize` (`equipment_type.*`),
    nome trimado + unicidade case-insensitive (`ErrNameTaken` → 409), guarda de
    remoção se houver equipamentos (`ErrInUse` → 409). Rotas `/v1/equipment-types`.
  - `postgres.IsUniqueViolation` / `IsForeignKeyViolation` (helpers de `pgconn.PgError`).

- **`internal/equipments`** ✅ — folha da hierarquia Local > Equipamento (spec §7.5).
  - `migrations/00011_equipments.sql`: `app.equipments` com 3 FKs compostas
    (`organization_id`; `(org, location_id) → locations`; `(org, equipment_type_id)
    → equipment_types ON DELETE RESTRICT`), `installed_at date`, `cost numeric(14,2)`,
    índices (inclui `equipments_serial_idx` parcial), RLS, auditoria. Permissões
    `equipment.*` / `equipment.serial.*` / `equipment.cost.*` já vinham do seed 00006.
  - `internal/db/queries/equipments.sql` (list filtrável por `location_id`/`type_id`
    via `sqlc.narg`, busca por nome OU série).
  - `internal/equipments/{equipments.go,http.go}`: saída `map[string]any` com máscara
    de campo (`AuthorizeWith`) em `serial_number` (`equipment.serial.*`) e `cost`
    (`equipment.cost.*`); `Create` valida local e tipo na org (`ErrLocationNotFound`
    / `ErrTypeNotFound` → 422); `date`↔`YYYY-MM-DD`, `numeric`↔string decimal.
    Eventos `equipment.created/updated/deleted`. Rotas `/v1/equipments`.
  - Testes: CRUD (data/custo), filtro por local/tipo, FK cross-org rejeitada,
    isolamento, máscara de `cost` (read/write), forbidden, `ErrInUse` ao apagar tipo em uso.
  - `openapi.yaml` + drift atualizados; `app.equipment_types`/`app.equipments` no
    `testdb.truncateSQL`. Suíte completa `go test -race -p 1 ./...` verde.

- **`internal/serviceordertypes` + `internal/serviceorders`** ✅ — ordens de
  serviço, fatia do cabeçalho + máquina de estados (spec §7.6, §22.5).
  - `migrations/00012_service_order_types.sql`: permissões `service_order_type.*`
    no catálogo + templates + backfill dos perfis `is_system` + bump de
    `permission_version`. `app.service_order_types` (molde de `equipment_types`:
    `UNIQUE (organization_id, id)`, índice único `(organization_id, lower(name))`,
    RLS, auditoria).
  - `migrations/00013_service_orders.sql`: `ALTER TABLE app.equipments ADD
    CONSTRAINT equipments_org_id_uk` (faltava p/ a FK composta); `app.service_orders`
    com 5 FKs compostas com `organization_id` (client obrigatório; location/
    equipment/type/assigned opcionais), `status` (draft/open/in_progress/
    completed), campos textuais do atendimento, `scheduled_for`/`started_at`/
    `completed_at`, índices (inclui `(organization_id, equipment_id, created_at)`
    spec §21), RLS, auditoria.
  - `internal/db/queries/service_order_types.sql` + `service_orders.sql`
    (list filtrável por client/location/equipment/assigned/status via `sqlc.narg`;
    `SetServiceOrderStatus` p/ transições) → sqlc.
  - `internal/serviceordertypes/{serviceordertypes,http}.go`: molde de
    `equipmenttypes` (`View` tipada, unicidade case-insensitive → 409, guarda de
    remoção → 409). Rotas `/v1/service-order-types`.
  - `internal/serviceorders/{serviceorders,http}.go`: `View` tipada (sem máscara
    de campo). `List/Get/Create/Update` + `Start` (open→in_progress, exige
    `service_order.update`) + `Complete` (in_progress→completed, exige
    `service_order.complete`) + `Reopen` (completed→in_progress). `Create` valida
    client/location/equipment/type/assigned na org e deriva `location_id` do
    equipamento; `Update` só em draft/open/in_progress (`ErrNotEditable` → 409).
    Eventos `service_order.created/updated/started/completed/reopened`. Rotas
    `/v1/service-orders` + `/{id}/{start,complete,reopen}`.
  - `cmd/servicelog-api/deps.go`: `SOTypes` + `SOrders` montados e roteados.
  - `openapi.yaml` + drift atualizados; `app.service_orders`/`app.service_order_types`
    no `testdb.truncateSQL`. Suíte completa `go test -race -p 1 ./...` verde.
  - Testes: `serviceordertypes_test.go` (CRUD, unicidade, isolamento, forbidden);
    `serviceorders_test.go` (CRUD, máquina de estados, trava otimista, filtros,
    validações de FK/mismatch/assignee, isolamento §26.1, forbidden).

- **`internal/people` + `internal/companies`** ✅ — pessoa e empresa (spec §5, §10).
  Modelo: **Organização = conta/tenant**; **Empresa = emitente** de laudo/
  orçamento/etiqueta (0..N por org); **Pessoa = dados pessoais 1:1 com o usuário**,
  global.
  - `migrations/00014_people.sql`: `iam.people` (1:1 com `iam.users`, sem RLS —
    padrão iam; `id` próprio p/ a trigger `audit_row_history`; `iam.set_updated_at`).
    Campos: `full_name`, `tax_id` (CPF), `phone`, `professional_registration`
    (CREA/CFT — aparece no laudo), `notes`.
  - `migrations/00015_companies.sql`: permissões `company.*` no catálogo +
    templates (admin=tudo, viewer/technician=read) + backfill + bump de
    `permission_version`. `app.companies` (`kind` `legal`|`individual`;
    `person_user_id` sem FK física p/ `iam.users` quando individual — CHECK amarra
    kind↔person; `UNIQUE (organization_id, id)`; índice único
    `(organization_id, lower(name))` e `(organization_id, person_user_id)` p/ no
    máximo uma individual por pessoa; RLS, auditoria). `app.company_members`
    (M:N pessoa↔empresa dentro da org, `is_primary` com única primária por
    pessoa; FK composta p/ `companies`; RLS, auditoria).
    `ALTER TABLE app.service_orders ADD COLUMN company_id` + FK composta
    `(organization_id, company_id)` ON DELETE RESTRICT + índice.
  - `internal/db/queries/{people,companies,company_members}.sql` + `service_orders.sql`
    (filtro/params `company_id`) → sqlc.
  - `internal/people/{people,http}.go`: `GET`/`PATCH /v1/me/person` (upsert campo
    a campo, sem permissão de catálogo — barreira é o principal; evento
    `person.updated`).
  - `internal/companies/{companies,members,http}.go`: `View` tipada.
    `List` (filtro `kind`) / `Get` / `Create` / `Update` (trava otimista; `kind` e
    `person_user_id` imutáveis) / `Delete` (bloqueia se houver ordens →
    `ErrInUse`) via `Authorize("company.*")`; `kind='individual'` exige pessoa
    membro ativo e no máximo uma por pessoa (`ErrPersonHasCompany`). Sub-recurso
    `/{id}/members` (GET/POST) e `/{id}/members/{userId}` (PATCH primária/DELETE),
    gerido por `company.update`. Eventos `company.created/updated/deleted/
    member_added/member_updated/member_removed`. Rotas `/v1/companies`.
  - `internal/serviceorders`: `company_id` opcional no cabeçalho (View, Create,
    Update, filtro de List); `resolveRefs` valida a empresa na org
    (`ErrCompanyNotFound` → 422). Quando nulo, o app pergunta qual empresa usar ao
    montar laudo/orçamento (spec §7.6) — ou segue sem.
  - `cmd/servicelog-api/deps.go`: `People` + `Companies` montados e roteados.
  - `openapi.yaml` + drift atualizados; `iam.people`/`app.companies`/
    `app.company_members` no `testdb.truncateSQL`.
  - Testes: `people_test.go` (get vazio → upsert → merge; pessoa é por-usuário);
    `companies_test.go` (CRUD, unicidade, `kind=individual` exige/limita pessoa,
    `ErrInUse`, vínculos add/primária/remover, isolamento §26.1, forbidden);
    `serviceorders_test.go` estendido (emitente + filtro + FK cross-org).

- **`internal/serviceorders` › peças e materiais** ✅ — sub-recurso
  `/v1/service-orders/{id}/parts` (spec §7.6 "Peças e materiais").
  - `migrations/00016_service_order_parts.sql`: `ALTER TABLE app.service_orders
    ADD CONSTRAINT service_orders_org_id_uk` (faltava p/ a FK composta a partir de
    peças). Permissões `service_order_part.{read,create,update,delete}` +
    campos `service_order_part.cost.{read,write}` (`is_field`) no catálogo +
    templates (admin=tudo; viewer=`.read`; technician=read/create/update +
    `cost.read`, **sem** delete/`cost.write`) + backfill + bump de
    `permission_version`. `app.service_order_parts` (FK composta
    `(organization_id, service_order_id) → app.service_orders ON DELETE CASCADE`;
    `description`, `part_number`, `quantity numeric(14,3)`, `unit`,
    `unit_cost`/`unit_price numeric(14,2)` sensíveis, `notes`; 7 colunas padrão;
    `set_row_defaults` + `audit_row_history`; RLS ENABLE/FORCE/policy).
  - `internal/db/queries/service_order_parts.sql` → sqlc.
  - `internal/serviceorders/parts.go`: saída em `map[string]any` com máscara campo
    a campo (`AuthorizeWith` + `Effective.FilterReadable`/`UnauthorizedWrites`) no
    grupo `cost` (`unit_cost` + `unit_price`), molde de `internal/equipments`.
    `ListParts`/`AddPart`/`UpdatePart`/`DeletePart`; escrita só com a ordem em
    estado editável (`ErrNotEditable` → 409); `quantity` formatada sem zeros à
    direita; peça sempre confere `service_order_id` (`ErrPartNotFound`). Eventos
    `service_order_part.created/updated/deleted`. Rotas em `serviceorders.Routes`
    (nada novo no `deps.go`).
  - `openapi.yaml` + drift atualizados; `app.service_order_parts` no
    `testdb.truncateSQL`.
  - Testes: `parts_test.go` (CRUD, `quantity` padrão + validação, gate de estado
    editável em add/update/delete, máscara de `cost` read+write, isolamento §26.1
    + peça de outra ordem, forbidden). Suíte completa `-race -p 1 ./...` verde.
  - Verificação de segurança: `check-sql` + `sqlc diff` limpos; todo SQL cru são
    literais `audit.log_event(...)` com `$N`; `organization_id` sempre de
    `p.OrganizationID`; migrations sem SQL dinâmico. Introspção confirma 7 colunas
    padrão + `audit_row_history` + `set_row_defaults` + RLS FORCE nas 3 tabelas
    `app.*` novas (§ pessoa segue o padrão `iam.*`: sem RLS, `audit_row_history`
    ativo, `iam.set_updated_at`).

- **`internal/clients` › contatos** ✅ — sub-recurso `/v1/clients/{id}/contacts`
  (spec §7.3 "pessoa de contato", §17.5 "contatos"). 1:N: `app.clients` mantém
  `contact_person` (texto livre), esta tabela é a lista completa.
  - `migrations/00017_client_contacts.sql`: `app.client_contacts` (FK composta
    `(organization_id, client_id) → app.clients ON DELETE CASCADE`; `name`, `role`
    (cargo), `phone`, `email`, `is_primary`, `notes`; índice único parcial de
    um primário por cliente; 7 colunas padrão; `set_row_defaults` +
    `audit_row_history`; RLS ENABLE/FORCE/policy). **Sem chave de catálogo
    própria** — gerido sob `client.read` (ver) / `client.update` (gerir), como
    `app.company_members`. Sem backfill.
  - `internal/db/queries/client_contacts.sql` → sqlc.
  - `internal/clients/contacts.go`: `ContactView` tipada, `ListContacts`/
    `AddContact`/`UpdateContact`/`DeleteContact`; marcar um contato primário
    desmarca o anterior; peça sempre confere `client_id` (`ErrContactNotFound`);
    trava otimista por `version`. Eventos `client_contact.created/updated/deleted`
    (com `contact_id` no metadata). Rotas em `clients.Routes` (nada novo no `deps.go`).
  - `openapi.yaml` + drift atualizados; `app.client_contacts` no `testdb.truncateSQL`.
  - Testes: `contacts_test.go` (CRUD, troca de primário, trava otimista,
    cliente/contato inexistente, contato de outro cliente, isolamento §26.1,
    forbidden). Suíte completa `-race -p 1 ./...` verde.
  - Segurança: `check-sql` + `sqlc diff` limpos; SQL cru só `audit.log_event(...)`
    com `$N`; `organization_id` de `p.OrganizationID`; introspecção confirma 7
    colunas padrão + `audit_row_history` + `set_row_defaults` + RLS FORCE + FK
    composta com `organization_id`.

- **Cliente PF/PJ + local com endereço e hierarquia + contatos de local** ✅ —
  ajuste pedido pelo usuário (spec §7.3, §7.4).
  - `migrations/00018_clients_pj_locations_tree.sql`:
    - `app.clients` ganha `kind` (`individual`|`legal`, imutável; padrão `legal`,
      espelha `app.companies`) + `legal_name` (razão social).
    - `app.client_contacts`: `name` vira opcional (`DEFAULT ''`) + `is_whatsapp`.
    - `app.locations`: endereço estruturado (`postal_code`, `street`, `number`,
      `complement`, `district`, `city`, `state` com CHECK de UF) — a coluna
      `address` (texto) migra para `street` e some. `parent_location_id` (auto-
      referência, FK composta com `organization_id`, `ON DELETE RESTRICT`):
      hierarquia filial > departamento > … O `contact_person`/`phone` continuam
      como contato rápido.
    - `app.location_contacts` (nova, molde de `client_contacts` + `is_whatsapp`),
      sob `location.read`/`location.update`. Sem chave de catálogo, sem backfill.
  - sqlc: `clients.sql`/`client_contacts.sql`/`locations.sql` atualizados +
    `location_contacts.sql` novo.
  - `internal/clients`: `Input.Kind` (só na criação), `legal_name`, filtro `kind`
    na lista, busca também por razão social. Contato: `is_whatsapp`, nome
    opcional (exige nome **ou** telefone).
  - `internal/locations`: `Address` estruturado + validação de UF (`ErrBadState`);
    `Filter{ClientID, ParentID, RootsOnly, Search}`; `Create` valida o pai
    (existe, mesmo cliente, profundidade ≤ 20 → `ErrParentNotFound`/
    `ErrParentOtherClient`/`ErrTooDeep`); `Delete` bloqueia se houver sublocais
    (`ErrHasChildren` → 409). Pai é imutável por ora (reparent fica p/ depois).
    `internal/locations/contacts.go`: sub-recurso `/v1/locations/{id}/contacts`.
    Eventos `location_contact.created/updated/deleted`.
  - `openapi.yaml` (schemas `Address`, `Location*`, `Client*`, `*Contact*`;
    paths de contatos de local; filtros `kind`/`parent_location_id`/`roots`) +
    drift OK; `app.location_contacts` no `testdb.truncateSQL`.
  - Testes: `clients_test` (PF/PJ, filtro por kind, kind inválido) + `contacts_test`
    (is_whatsapp, contato só com telefone); `locations_test` (endereço + UF
    inválida, hierarquia filial→departamento, pai de outro cliente, filtros
    `parent`/`roots`, delete bloqueado com sublocal, contatos de local).
    Suíte completa `-race -p 1 ./...` verde. Introspecção confirma padrão de
    auditoria/RLS/FK nas 4 tabelas.

- **`internal/serviceorders` › recomendações** ✅ — sub-recurso
  `/v1/service-orders/{id}/recommendations` (spec §7.6 "Recomendações"). O campo
  texto `service_orders.recommendations` continua (nota livre no laudo); esta
  tabela é a lista estruturada de recomendações para a próxima visita.
  - `migrations/00019_service_order_recommendations.sql`: `app.service_order_recommendations`
    (FK composta `(organization_id, service_order_id) → app.service_orders ON DELETE
    CASCADE`; `description`, `priority` `low|medium|high`, `status`
    `open|addressed|dismissed`, `notes`; 7 colunas padrão; `set_row_defaults` +
    `audit_row_history`; RLS ENABLE/FORCE/policy). **Sem chave de catálogo** —
    gerido sob `service_order.read`/`service_order.update` (sem campo sensível).
    Sem backfill.
  - `internal/db/queries/service_order_recommendations.sql` → sqlc.
  - `internal/serviceorders/recommendations.go`: `RecommendationView` tipada;
    `List/Add/Update/Delete`; validação de `priority`/`status`
    (`ErrBadPriority`/`ErrBadRecStatus`); escrita só com a ordem em estado
    editável (`ErrNotEditable` → 409); confere `service_order_id`
    (`ErrRecNotFound`); trava otimista. Eventos
    `service_order_recommendation.created/updated/deleted`. Rotas em
    `serviceorders.Routes` (nada novo no `deps.go`).
  - `openapi.yaml` + drift atualizados; `app.service_order_recommendations` no
    `testdb.truncateSQL`.
  - Testes: `recommendations_test.go` (CRUD, prioridade padrão, validação de
    enums, gate de estado editável em add/update, isolamento §26.1 + recomendação
    de outra ordem, forbidden). Suíte completa `-race -p 1 ./...` verde.
    Introspecção confirma 7 colunas padrão + `audit_row_history` +
    `set_row_defaults` + RLS FORCE + FK composta.

- **Armazenamento de objetos (S3-compatível / MinIO)** ✅ — **ADR-0012**. Destrava
  fotos, assinatura e PDF do laudo (spec §13.3, §19.7, §26.4, §30).
  - `internal/platform/blob` — fachada fina sobre `minio-go/v7`:
    `Put/Get/Stat/Delete/PresignGet/Ping`. `blob.Key(orgID, parts...)` força o
    prefixo `org/{organization_id}/…` (isolamento por prefixo, spec §14.2). Bucket
    único privado; download só por URL assinada e temporária (`S3_PRESIGN_TTL`,
    default 15 min).
  - `config.Blob` (`S3_ENDPOINT` vazio = AWS; `S3_REGION/BUCKET/ACCESS_KEY/
    SECRET_KEY/USE_SSL/PRESIGN_TTL`). Opcional: sem `S3_BUCKET` ou com o store
    fora, `deps.Blob = nil`, `/readyz` reporta `blob: error` e **só os endpoints
    de anexo** respondem 503 — o resto da API funciona (spec §20).
  - `cmd/servicelog-api`: `deps.Blob` + check `blob` no `/readyz` (boot tolerante).
  - compose dev: serviço `minio` (API :9000, console :9001) + volume `miniodata`
    (bucket criado sozinho por `blob.Connect` na primeira conexão — sem container
    de setup); `servicelog-api` e `worker` recebem `S3_*`. compose prod: `minio`
    ligado (volume `miniodata`),
    trocar por S3 gerenciado = remover o serviço e ajustar `S3_*` no `prod.env`.
  - `.env.example` / `deploy/prod.env.example` atualizados.
  - Testes: `internal/platform/blob/blob_test.go` — round-trip
    Put/Get/Stat/Delete + `PresignGet` (baixa via HTTP, checa `Content-Disposition`)
    + `Key` sempre prefixado. Integração, pulado sem `TEST_S3_*`.
  - **Metadados no Postgres, bytes no store** (spec §19.7): as próximas tabelas
    (`service_order_photos`, `service_order_signatures`) guardam `blob_key`,
    `content_type`, `size_bytes`, `sha256` + colunas padrão + RLS; o store só o
    conteúdo.

- **`internal/serviceorders` › fotos e assinatura** ✅ — sub-recursos
  `/v1/service-orders/{id}/photos` e `/v1/service-orders/{id}/signature`
  (spec §7.6, §19.7, §26.4; ADR-0012). Sem campo sensível → geridos sob
  `service_order.read`/`service_order.update`, no molde de recomendações.
  - `migrations/00020_service_order_photos.sql`: `app.service_order_photos`
    (`blob_key` único, `content_type`, `size_bytes` (`> 0`), `sha256`
    (`CHECK` hex/64), `kind` `before|after|other` padrão `other`, `caption`;
    FK composta `(organization_id, service_order_id)`; 7 colunas padrão +
    `set_row_defaults` + `audit_row_history` + RLS FORCE).
  - `migrations/00021_service_order_signatures.sql`: `app.service_order_signatures`
    (mesmos metadados, sem `kind`/`caption`) + **índice único parcial**
    `(service_order_id) WHERE deleted_at IS NULL` — no máximo uma assinatura
    ativa por ordem; reenviar faz soft-delete da anterior + insert na mesma
    transação (`PutSignature`).
  - `internal/db/queries/service_order_{photos,signatures}.sql` → sqlc.
  - `internal/serviceorders/{photos,signature}.go`: `AddPhoto/ListPhotos/
    DeletePhoto/PhotoDownloadURL`, `PutSignature/GetSignature/DeleteSignature/
    SignatureDownloadURL`. Upload só grava no `blob` + insere metadados numa
    ordem editável; download é sempre `blob.PresignGet` (nunca serve o binário
    pela API); `s.blob == nil` → `ErrBlobUnavailable` (503, spec §20) sem
    tocar o banco.
  - **Camada HTTP** (`readUploadFile` em `http.go`): lê `multipart/form-data`,
    detecta o `content_type` real pela **assinatura de bytes**
    (`http.DetectContentType`) — nunca pelo header que o cliente declarou —
    contra um allowlist (`image/jpeg`+`image/png` para fotos, só `image/png`
    para assinatura, spec §30) e calcula o SHA-256. Teto por arquivo (8 MiB
    foto / 2 MiB assinatura) + teto do corpo da requisição elevado só no
    `servicelog-api` (`httpx.NewRouter(logger, maxUploadBodyBytes)`, 10 MiB —
    `http.MaxBytesReader` não permite afrouxar um limite menor já aplicado
    por um middleware pai, então o teto vale pro serviço inteiro, não só pras
    rotas de anexo). Download sempre com `Content-Disposition: attachment`
    (nome derivado do `content_type` detectado, nunca do nome enviado pelo
    cliente) — sem servir imagem/HTML disfarçado inline no navegador.
  - Testes: `upload_internal_test.go` (unidade, sem banco/blob) cobre
    especificamente spoofing — Content-Type declarado divergente do real,
    payload `<script>` com nome/Content-Type de `.png` rejeitado por tipo,
    teto de tamanho, arquivo ausente/vazio. `photos_test.go`/`signature_test.go`
    (integração, pulam sem `TEST_S3_*`): CRUD, round-trip via presign real
    (baixa por HTTP e compara bytes), gate de estado editável, isolamento
    §26.1 + ordem errada, forbidden, e `ErrBlobUnavailable` (sem depender de
    S3, roda sempre). `openapi.yaml` + drift + `testdb.truncateSQL`
    atualizados. Suíte completa `-race -p 1 ./...` verde.

- **`internal/pdfjobs` › PDF do laudo** ✅ — `/v1/service-orders/{id}/pdf`
  (GET status, POST enfileira) + `/{id}/pdf/download` (spec §7.6, §22.5, §25
  "processados em background"; ADR-0012). Geração é assíncrona: o
  `servicelog-api` só enfileira; o `worker` monta e grava no blob.
  - `migrations/00022_service_order_pdf.sql`: permissão dedicada
    `service_order.pdf` (gerar/consultar/baixar é ação distinta de editar a
    ordem; admin/technician/viewer = allow) + `app.service_order_pdf_jobs`
    (fila **sem RLS**, no molde de `iam.email_outbox` — infraestrutura,
    escaneada pelo worker em todas as orgs; cada linha carrega
    `organization_id`/`service_order_id`, sem dado de negócio). No máximo um
    job `pending` por ordem (índice único parcial); reenviar depois de
    `done`/`failed` é permitido.
  - `internal/serviceorders/pdf.go`: `RequestPDF` (só ordem `completed`,
    `ErrPDFAlreadyPending` se já houver job pendente) / `PDFStatus` /
    `PDFDownloadURL` (presign, como fotos/assinatura). Nunca renderiza nem
    escreve no blob — só enfileira e consulta.
  - `internal/pdfjobs` (`Dispatcher`, molde `internal/mailq`: claim
    `FOR UPDATE SKIP LOCKED` + backoff exponencial, 6 tentativas): por job,
    lê os dados sob `postgres.WithTenantTx` (RLS normal), baixa fotos/
    assinatura do blob, renderiza com `go-pdf/fpdf` (`render.go`, função pura
    e testável sem banco/S3) e grava em
    `org/{org}/service-orders/{so}/pdf/{job_id}.pdf`. `audit.log_event`
    (`service_order.pdf_generated`) roda numa transação de tenant à parte
    (a de claim não tem `app.organization_id` — a fila não usa RLS).
  - **Emitente**: cascata `service_orders.company_id` → empresa primária do
    técnico designado (`ListCompaniesForUser`, já ordenada por `is_primary`)
    → dados da Pessoa (`iam.people`, fallback `iam.users.name`) → segue sem
    bloco de emitente (spec §7.6, comentário da migration 00015).
  - Preço unitário das peças aparece no laudo (o cliente precisa ver o que
    está sendo cobrado); custo interno (`unit_cost`) nunca.
  - `cmd/worker`: conecta o blob store (boot tolerante, como o
    `servicelog-api`) e roda `pdfDispatcher.Loop` a cada 15s.
  - Testes: `render_test.go` (unidade, gera PDF de verdade a partir de dados
    fabricados, inclusive com foto/assinatura PNG reais via `image/png`) +
    `pdfjobs_test.go` (integração ponta a ponta: cria ordem completa com
    peça/recomendação/foto/assinatura, `RequestPDF` → `Dispatcher.RunOnce` →
    baixa a URL assinada e confere que o conteúdo é um PDF de verdade) +
    `serviceorders/pdf_test.go` (ordem precisa estar `completed`, um job
    pendente por vez, isolamento §26.1, forbidden). `openapi.yaml` + drift
    atualizados. Suíte completa `-race -p 1 ./...` verde.

- **`internal/companies` › logo** ✅ — `/v1/companies/{id}/logo` (POST grava/
  substitui, DELETE remove) + `/{id}/logo/download` (spec §5; ADR-0012).
  - `migrations/00023_company_logo.sql`: ao contrário de fotos/assinatura das
    ordens (histórico, várias linhas), o logo é 1:1 com a empresa → colunas
    (`logo_blob_key`, `logo_content_type`, `logo_size_bytes`, `logo_sha256`)
    direto em `app.companies`, não uma tabela própria. `CHECK` garante que os
    4 campos são preenchidos/limpos juntos; índice único parcial no
    `blob_key`. Gerido sob `company.read`/`company.update` (sem chave de
    catálogo, sem campo sensível).
  - **Refactor**: a validação de upload (multipart, content-type pela
    assinatura de bytes, allowlist, SHA-256 — antes vivia só em
    `internal/serviceorders`) subiu para `httpx.ReadUploadFile`
    (`internal/platform/httpx/upload.go`) — segundo consumidor real do mesmo
    código sensível a segurança, então parou de fazer sentido duplicar por
    pacote. `serviceorders` foi migrado para o helper compartilhado; os
    testes de spoofing/tipo/tamanho foram junto para
    `internal/platform/httpx/upload_test.go`.
  - `internal/companies/logo.go`: `SetLogo` (UPDATE simples, sem soft-delete-
    e-insert como a assinatura — não é histórico) / `DeleteLogo` /
    `LogoDownloadURL` (presign, como fotos/assinatura/pdf). JPEG ou PNG até
    2 MiB. `company.Logo` (metadados) aparece embutido no `View` da empresa.
  - Testes: `logo_test.go` — set/get/download real via presign, replace,
    delete + re-delete (`ErrLogoNotFound`), `ErrBlobUnavailable` (sem
    depender de S3), isolamento §26.1. `openapi.yaml` + drift atualizados.
    Suíte completa `-race -p 1 ./...` verde.

- **`internal/locations` › reparent** ✅ — `PATCH /v1/locations/{id}/parent`
  (`parent_location_id` nullable + `version`; optimistic lock). Move um
  sublocal (departamento) para outro pai dentro do mesmo cliente, ou para a
  raiz (`null`). `ErrParentNotFound`/`ErrParentOtherClient`/`ErrTooDeep` já
  existiam (usados no `Create`); `ErrParentCycle` já estava declarado e
  mapeado no `writeErr` mas nunca usado — só faltava este método.
  - `internal/locations/locations.go`: `Reparent` + `assertValidNewParent`
    (sobe a cadeia de pais a partir do pai novo; `ErrParentCycle` se
    encontrar o próprio local no caminho — seria descendente dele —,
    `ErrTooDeep` se estourar `maxTreeDepth`). Reusa `UpdateLocation` (a
    query já aceitava `parent_location_id`; só o método de serviço não
    exigia). Os demais campos do local não mudam.
  - Testes: `TestReparent` — move entre filiais, move para raiz, version
    conflict, pai de outro cliente, pai inexistente, ciclo direto (virar
    pai de si mesmo) e ciclo indireto (mover uma filial para dentro do
    próprio descendente). `openapi.yaml` + drift atualizados.

- **`internal/labels` › etiquetas / QR Codes** ✅ — spec §8-§12; **ADR-0013**
  fecha o vínculo polimórfico que a própria spec pedia em ADR. Permissões
  (`label.*`, `label_batch.*`) já vinham seedadas desde a 00006 — só faltavam
  as tabelas e o serviço.
  - `migrations/00024_labels.sql`: `app.qr_codes` (vínculo por 3 colunas
    nulláveis + **FK composta real** por tipo — não `entity_type`/`entity_id`
    solto —, `CHECK` de cardinalidade, índices únicos parciais garantindo no
    máximo uma etiqueta `assigned` por cliente/local/equipamento, spec §8.8);
    `app.qr_batches` (lotes, spec §9); `app.qr_assignment_attempts` (log de
    tentativas — inclusive as recusadas por conflito, spec §12.3; sem 7
    colunas padrão, é log, não registro de negócio). RLS FORCE nas três.
  - **Código textual** (spec §8.2): alfabeto de 32 símbolos sem `0/O`/`1/I`,
    16 chars de payload (`crypto/rand`, ~80 bits) + 1 dígito verificador,
    formato `SL-XXXX-XXXX-XXXX-XXXX-C` — fecha a decisão adiada no
    `GUIA-BACKEND-NEGOCIO.md` §8.
  - **"Primeira confirmação vence"** (spec §12.1) sem lock manual nem
    `version`: `Assign` faz `UPDATE ... WHERE status IN ('available',
    'reserved')`; a cláusula é a própria trava de concorrência — 0 linhas
    afetadas = conflito, registrado em `qr_assignment_attempts` com
    `result='conflict'`, o vínculo vencedor nunca muda.
  - `internal/labels/labels.go`: `Create` (livre ou já vinculado — atômico:
    se o destino já tiver etiqueta ativa, nada é criado, spec §8.5),
    `Get`/`Resolve` (por código, aceita com/sem separadores, spec §8.6, com
    resumo do destino para a tela pós-scan, spec §8.7), `FindActiveFor`
    (etiqueta ativa de uma entidade), `Assign`, `Replace` (a antiga vira
    `replaced` sem apagar o vínculo — é histórico, spec §12.5),
    `Deactivate`.
  - `internal/labels/batches.go`: `CreateBatch` (gera N códigos livres),
    `ReserveBatch` (técnico/dispositivo, prepara sincronização offline —
    spec §11.2, ainda não implementada), `ExportBatch` (marca emitido;
    reexportar/reimprimir é permitido e só incrementa o contador, spec
    §9.3), `MarkBatchLost` (só as etiquetas ainda não vinculadas — uma já
    colada no equipamento não se perde por marcação de lote, spec §9.4).
  - **Fora do escopo desta entrega** (registrado no ADR-0013 para não
    reabrir a decisão à toa): sinalização de `REPLACEMENT_REQUIRED` nas
    entidades-alvo (é UX do app, spec §12.4), modelos de impressão / PDF
    físico da etiqueta (spec §10 — reaproveitar `internal/pdfjobs` quando
    entrar), motivo obrigatório de reimpressão, perda de intervalo dentro
    de um lote, criação de código offline (depende da Fase de sincronização,
    spec §19).
  - Testes: `labels_test.go` (17 casos) + `batches_test.go` (6 casos) —
    criar+vincular atômico, conflito de segunda confirmação, entidade já
    rotulada, replace preserva histórico, resolve com/sem separadores e
    código inválido, isolamento §26.1, forbidden, lote (criar/reservar/
    exportar+reexportar/perder — etiqueta já vinculada não perde).
    `openapi.yaml` + drift atualizados. Suíte completa `-race -p 1 ./...`
    verde.

- **`internal/sync` › sincronização** ✅ — `POST /v1/sync/push`,
  `GET /v1/sync/pull`, `GET /v1/sync/bootstrap` (spec §19, §22.7).
  **ADR-0014**: infraestrutura completa, só `clients` ligada de ponta a
  ponta como prova (ligar mais uma entidade é mecânico — 4 passos sempre
  iguais, documentados no ADR).
  - `migrations/00025_sync.sql`: `app.outbox_events` guarda **ponteiro**
    (`entity_type`/`entity_id`/`operation`), não payload — o `pull` busca o
    estado atual na tabela de origem (via o `Get` de cada entidade, RLS +
    máscara de campo aplicados normalmente); `seq` (`bigint identity`) é o
    cursor direto. Trigger genérica `app.record_outbox_event()` (molde
    `audit.capture_row_change`, ADR-0005), anexada por enquanto só em
    `app.clients`; detecta "delete" pela transição `deleted_at NULL → NOT
    NULL` num `UPDATE` (soft delete), não por `TG_OP='DELETE'`.
    `app.sync_applied_operations` dá idempotência ao push por
    `operation_id` (spec §19.4).
  - `internal/sync`: `Adapter` (interface por tipo de entidade — `Get`,
    `List`, `ApplyCreate/Update/Delete`) faz a ponte entre o protocolo
    genérico e o serviço tipado; nenhuma regra de negócio mora em
    `internal/sync`, só delega. `clients.CreateWithID` (spec §19.1: ID vem
    do dispositivo, nunca sequence do servidor) e
    `clients.DecodeSyncPayload` (decodifica o mesmo `body` do HTTP) foram
    adicionados ao pacote `clients` para viabilizar o adaptador.
  - Conflito de `update` reaproveita `ErrVersionConflict` que `Update` já
    tinha; `delete` é idempotente como o REST já era. `pull` colapsa
    múltiplas mudanças da mesma entidade numa página num só item (sempre
    estado atual, nunca sequência de deltas) sem perder o cursor.
  - Testes (11 casos): create+pull, idempotência por `operation_id`,
    conflito de versão, tombstone no pull, dedup de mudanças repetidas,
    tipo de entidade desconhecido, forbidden, isolamento §26.1 (pull e
    push cross-tenant), bootstrap + cursor de continuação.
    `openapi.yaml` + drift atualizados. Suíte completa `-race -p 1 ./...`
    verde.

- **Hardening `servory_business`/`servory_worker`** ✅ — `ADR-0015`.
  Dois papéis de menor privilégio (não mais `servory_app` compartilhado)
  para `servicelog-api` e `worker`, com allowlist explícita tabela por
  tabela em `iam.*` — `iam.refresh_tokens`/`iam.password_reset_tokens`/
  `iam.devices` nunca concedidos a nenhum dos dois.
  - `migrations/00026` (`servory_business`) e `00027` (`servory_worker`):
    `app`/`audit` com acesso completo (`ALTER DEFAULT PRIVILEGES`, mesmo
    padrão do `servory_app`); `iam` sem privilégio de schema nem default
    privileges, só `GRANT` explícito por tabela.
  - Divergência que motivou dois papéis em vez de um: `iam.email_outbox`
    — `servory_business` só `INSERT` (enfileirar convite),
    `servory_worker` `SELECT/UPDATE/DELETE` (processar a fila,
    `internal/mailq.Dispatcher`) sem `INSERT`. Um papel só compartilhado
    deixaria o `servicelog-api` ler o link de redefinição de senha que o
    `auth-api` enfileira na mesma fila.
  - `GetUserByID` e a nova `GetUserProfileByNormalizedEmail` trocaram
    `SELECT *` por lista de colunas explícita sem `password_hash` — mesmo
    que uma query rode sob o papel restrito, a coluna não trafega para
    dentro do processo.
  - `deploy/postgres/initdb/00-roles.sh` cria os quatro papéis;
    `scripts/db.sh` concede `CONNECT` a todos em bancos novos (dev/test).
    Dev: `docker-compose.yml` já usa `servory_business`/`servory_worker`
    por padrão. Prod: `docker-compose.prod.yml` sobrescreve `POSTGRES_DSN`
    via `env_file: [prod.env, prod-business.env]` (e `prod-worker.env`) —
    arquivos `.example` novos, `prod.env` continua só com o DSN do
    `auth-api` (`servory_app`).
  - Verificação ao vivo (não só suíte de testes, que ainda roda com
    `servory_app` sem restrição): `auth-api`/`servicelog-api`/`worker`
    reais contra os DSNs restritos — login, `GET /v1/me`,
    `PATCH /v1/me/person`, criar convite (`INSERT` em `email_outbox` via
    `servory_business`) e o worker despachando o e-mail
    (`SELECT`/`UPDATE` em `email_outbox` via `servory_worker`,
    confirmado no Mailpit).
  - Fechado depois (ver "Volume de chave JWT separado" mais abaixo,
    `ADR-0021`).

- **`internal/sync` › locations e equipments ligados** ✅ — `ADR-0014`
  atualizado. Migration `00028` anexa o trigger genérico nas duas tabelas;
  `locations.CreateWithID` e `equipments.CreateWithID` novos (mesmo molde de
  `clients.CreateWithID`); `locations.DecodeCreateSyncPayload`/
  `DecodeUpdateSyncPayload` e `equipments.DecodeCreateSyncPayload`/
  `DecodeUpdateSyncPayload` decodificam o payload do push reusando o `body`
  do HTTP. Novo `locationAdapter`/`equipmentAdapter` em
  `internal/sync/adapters.go`; `locations.Get/List` devolvem `View` (struct
  tipado, não `map[string]any`) — `structToMap` (round-trip JSON) faz essa
  conversão só para essa entidade. Registrados em `cmd/servicelog-api/
  deps.go`. 8 testes novos em `internal/sync/sync_test.go` (create+pull,
  cliente inexistente rejeitado, conflito de versão, delete+tombstone,
  bootstrap) — suíte completa e `make lint` verdes.
  - `service_orders` e etiquetas ficam para quando o app Flutter precisar:
    `service_orders` tem máquina de estados e sub-recursos (peças, fotos,
    assinatura, PDF) que não mapeiam para create/update genéricos sem
    decidir o que "sincronizar uma ordem" significa — não é mais receita
    mecânica pura como locations/equipments foram.

- **PDF físico da etiqueta** ✅ — `ADR-0016` (spec §9.1, §10). Reaproveita
  `internal/pdfjobs` (mesmo molde do laudo): `labels.RequestBatchPDF`
  enfileira (`app.label_batch_pdf_jobs`, migration `00029`, só lote já
  `issued`); novo `pdfjobs.LabelDispatcher` (`labeljobs.go`) processa —
  lê os códigos sob RLS, renderiza (`labelrender.go`) e grava no blob
  store; `cmd/worker` ganha um terceiro `Loop`. Reusa a permissão
  `label_batch.export` (nenhuma nova). Folha A4, grade 3×6 (18
  etiquetas/página); modelo completo (QR + código + empresa, spec §10.1)
  ou compacto (só código + empresa, spec §10.2) via `format`; `company_id`
  opcional identifica a empresa emissora exibida (sem cascata — a decisão
  de qual empresa é explícita de quem chama, não existe "empresa primária
  da organização" hoje). Nova dependência `github.com/skip2/go-qrcode`
  (MIT) para gerar a imagem do QR — nenhuma lib de QR existia no projeto.
  Rotas `GET/POST /v1/qr-batches/{id}/pdf` +
  `GET .../pdf/download`, `openapi.yaml` atualizado. Testes: renderização
  pura (`labelrender_test.go`), fluxo de enfileiramento/status/download
  (`labels/pdf_test.go`) e pipeline completo com blob store real
  (`pdfjobs/labeljobs_test.go`). Verificado ao vivo: lote de 5 etiquetas
  gerado, baixado e inspecionado — QR + código + dados da empresa
  corretos, layout batendo com o modelo da spec.
  - Fora do escopo: layout "etiqueta individual"/impressora térmica; texto
    padrão configurável por organização (spec §10.3, ver ADR).

- **Modelos de etiqueta (texto congelado)** ✅ — `ADR-0017` (spec §10.3).
  Entidade nova `internal/labeltemplates` (CRUD, molde `equipmenttypes`,
  `/v1/label-templates`): texto livre multilinha, opcionalmente derivado de
  uma empresa na criação (pré-preenchido) mas **congelado** dali em diante
  — não segue mudanças posteriores na empresa. `labels.RequestBatchPDF`
  ganha `template_id` ao lado do `company_id` já existente (ADR-0016) —
  mutuamente exclusivos (`ErrConflictingPDFSource`, também travado por
  `CHECK` no banco). `internal/pdfjobs/labelrender.go` refatorado para
  receber `infoLines []string` já resolvido (empresa ao vivo ou modelo
  congelado) em vez de um `emitter` estruturado. Permissão nova
  `label_template.{read,create,update,delete}` (admin: tudo;
  technician/viewer: só leitura). Testes de CRUD/validação de limite,
  conflito de fonte, e pipeline completo com modelo salvo contra MinIO
  real. Verificado ao vivo com o exemplo exato do usuário ("Empresa
  {{razão social}} / CNPJ {{...}} / Telefone {{...}}" como texto livre,
  sem placeholder de verdade — só o texto digitado).
  - **Bug sistêmico descoberto e corrigido** (`migrations/00031`): o
    backfill de permissão de migrations antigas (padrão usado desde a
    00010) silenciosamente não afeta organizações já existentes —
    `app.roles`/`app.role_permissions`/`app.organization_memberships` têm
    `FORCE ROW LEVEL SECURITY`, e migrations rodam sem contexto de tenant,
    então a policy filtra tudo mesmo para o dono da tabela. Corrigido só
    para `label_template` nesta entrega; **outras migrations antigas
    (00010, 00016, 00017, 00022, ...) têm o mesmo problema** e ficam como
    dívida técnica a resolver à parte (ver ADR-0017).
  - Fora do escopo: layout "etiqueta individual"/impressora térmica (ver
    ADR-0016).

- **`internal/sync` › service_orders ligado** ✅ — `ADR-0018`. Cabeçalho da
  ordem + peças sincronizam; transições de estado (`start`/`complete`/
  `reopen`) viram três novos `operation_type` no protocolo de push, aplicados
  por uma interface opcional nova (`sync.ActionApplier`) que só o adaptador
  de `service_order` implementa — os demais adaptadores não mudam nada.
  Transição inválida no estado atual do servidor (dispositivo com visão
  desatualizada) vira `conflict`/`VERSION_CONFLICT`, mesma família do
  conflito de `version` — sem bloqueio de conectividade nenhum: uma
  transição feita offline só precisa ser reenviada quando a conexão voltar,
  igual a qualquer outra mudança.
  - `service_order` não aceita `delete` (a API síncrona nunca expôs isso) —
    `sync.ErrOperationNotSupported` novo, mapeado para `BAD_OPERATION_TYPE`
    em vez de cair no genérico "erro interno".
  - `service_order_part`: como o protocolo só carrega o ID da própria peça
    (não o da ordem-pai), `loadPart`/`UpdatePart`/`DeletePart` generalizados
    para aceitar checagem de ordem-pai opcional; `GetPart`/
    `UpdatePartByID`/`DeletePartByID`/`ListAllParts` novos (métodos públicos
    comuns, não exclusivos de sync).
  - **Bug real encontrado e corrigido**: `version` sumia (ficava `nil`) em
    todo push bem-sucedido de entidade convertida por `structToMap`
    (`locations` e agora `service_order`) — `json.Unmarshal` decodifica
    número em `float64`, não `int32`, e o código só testava `int32`. Já
    afetava `locations` desde a entrega anterior sem nenhum teste pegar;
    corrigido com um helper (`versionOf`) que aceita os dois formatos.
  - PDF continua fora do sync (ADR-0014); ficou decidido na conversa que o
    PDF "de campo" (technician sem conexão) é responsabilidade do Flutter
    gerar localmente a partir do dado já capturado no dispositivo — o PDF do
    servidor continua sendo a cópia oficial, gerada quando a ordem
    sincroniza. Nenhuma mudança de backend decorre disso.
  - Verificado ao vivo: ordem criada via push, três transições em sequência
    (`start`→`complete`→`reopen`) confirmadas por `GET`, peça criada via
    push, tudo aparecendo certo no `pull`.
  - Fora do escopo ainda: fotos/assinatura/PDF (blob-backed, protocolo
    próprio, nunca fizeram parte do sync — ADR-0014).

- **`internal/sync` › qr_code e qr_batch ligados** ✅ — `ADR-0019`. Fecha o
  roadmap original de sincronização (nenhuma entidade de negócio pendente).
  `assign`/`replace`/`deactivate` (spec §8) viram três `operation_type`
  novos, aplicados por `qrCodeAdapter` (`ActionApplier`). Duas mudanças
  genéricas em `internal/sync` motivadas por etiqueta mas sem efeito em
  `service_order`: `ActionApplier.ApplyAction` ganhou um parâmetro
  `payload` (etiqueta precisa de dado extra — o destino de um `assign`, o
  ID da substituta em `replace` — que as transições de ordem nunca
  precisaram); o dispatch de ações deixou de hardcodar nomes
  (`"start"/"complete"/"reopen"`), qualquer `operation_type` fora de
  create/update/delete tenta `ActionApplier` genericamente.
  `assign`/`replace`/`deactivate` não usam `base_version` — a trava de
  concorrência de etiqueta nunca foi por `version` (ADR-0013), é o próprio
  `UPDATE ... WHERE status IN (...)`; uma visão desatualizada já vira
  `ErrCodeNotAvailable`/`ErrEntityAlreadyLabeled`/`ErrCodeNotAssigned`,
  traduzido para `conflict`. `qr_batch` é só leitura do lado do dispositivo
  (criar/reservar/exportar/perder lote continua exclusivamente REST/
  escritório) — `ApplyCreate/Update/Delete` sempre `ErrOperationNotSupported`.
  `labels.CreateWithID`/`ListAll` novos (mesmo molde das demais entidades).
  `openapi.yaml`: enum de `operation_type` corrigido (estava desatualizado
  desde o ADR-0018, só listava create/update/delete). Testes: criar
  etiqueta livre + pull, assign com/sem conflito de destino já vinculado,
  replace+deactivate em sequência via push, update/delete rejeitados, lote
  aparece em pull/bootstrap mas rejeita mutação. Suíte completa
  `-race -p 1 ./...` + `make lint` verdes.

- **Auditoria/correção do backfill de permissão de migrations antigas** ✅
  — `ADR-0020`. Levantamento no banco de dev (22 orgs) confirmou lacuna
  real em `service_order.pdf` (57 linhas, de 00022) e
  `service_order_part.*` (12 linhas, de 00016); `equipment_type`/
  `service_order_type`/`company` já estavam completos por acaso (nenhuma
  org atual é anterior a essas migrations). `permission_version` também
  estava quase sempre defasado — das 7 migrations que tentam bumpar, só a
  00031 (que já corrigia o bug) conseguia. Migration `00034` reaplica os
  cinco backfills originais (00010/00012/00015/00016/00022, todos
  `ON CONFLICT DO NOTHING`) dentro de uma janela `NO FORCE ROW LEVEL
  SECURITY`, mesma técnica de 00031, + um único bump de
  `permission_version`. Verificado ao vivo: 0 lacunas remanescentes em
  qualquer prefixo, todas as organizations com `permission_version`
  incrementado. Fecha a dívida técnica do ADR-0017/0031 — nenhuma
  migration de backfill de permissão conhecida continua quebrada (a causa
  raiz do padrão em si — escrever um backfill novo sem lembrar de desligar
  `FORCE ROW LEVEL SECURITY` — continua possível numa migration futura;
  ver "Consequências" do ADR-0020).

- **Volume de chave JWT separado (só pública)** ✅ — `ADR-0021`. Fecha o
  último item de hardening aberto pelo ADR-0015. `servicelog-api` passa a
  montar um volume novo (`jwtkeys-pub` em prod, `../secrets/jwt-pub` em
  dev) que só recebe `*.pub.pem` — nunca mais tem acesso de filesystem à
  chave privada, mesmo que `tokens.LoadVerifyKeySet` já só lesse a
  pública mesmo (defesa em profundidade no nível do container, não só do
  código). Auditando `cmd/worker`, nada nele chama `LoadKeySet`/
  `LoadVerifyKeySet` — o volume/env de chave que tinha era vestígio de
  copy-paste do molde de `servicelog-api`; removido por completo (menor
  privilégio de verdade aqui é nenhuma chave, não só a pública).
  `cmd/auth-api/commands.go`: `keygenCmd` ganha `TOKEN_PUBLIC_KEY_DIR`
  (opcional) — copia o `.pub.pem` pra lá depois de gerar/confirmar o par,
  idempotente. Verificado ao vivo: `make keys` (chave `dev` já existia)
  sincronizou a cópia pública; stack local subiu normalmente com
  `servicelog-api` verificando token pelo volume só-público.

- **Layout de etiqueta avulsa/impressora térmica** ✅ — `ADR-0022`. Fecha o
  último "fora de escopo" do ADR-0016. `format` ganha `thermal` (ao lado
  de `full`/`compact`): uma página por código, tamanho físico de bobina
  térmica (60×40mm) via `fpdf.NewCustom`/`AddPageFormat`, sempre com QR.
  `drawLabel` (o desenho do conteúdo em si) não mudou — só a montagem da
  página é diferente; `renderLabelSheet` virou um dispatcher fino entre o
  layout em grade (A4, já existia) e o novo (`renderThermalLabels`).
  Migration `00035` amplia o `CHECK` de `format` na fila de jobs — mesma
  permissão, mesmo endpoint, mesmo dispatcher do worker, nada novo de
  infraestrutura. Testes: renderização pura, validação do formato,
  pipeline completo contra blob store real.

- **`docs/GUIA-FLUTTER.md`** ✅ — guia de integração do app Flutter com este
  backend (molde de `docs/GUIA-BACKEND-NEGOCIO.md`): autenticação, sessão
  offline, permissões no cliente (UI apenas), banco local, protocolo de
  sync (as 7 entidades ligadas, `operation_type` por entidade), regra de
  conflito de etiqueta offline, PDF gerado no dispositivo (ADR-0018) e
  ordem sugerida de implementação. Linkado no README.

### Próximo

Nenhum item pendente conhecido do roadmap de negócio original.

---

## `feature/auth-foundation` — FASE 1 CONCLUÍDA (histórico)

Fundação de segurança (Fases 0–1 da spec) completa: M0–M6 ✅. Mergear em `main`.

## Concluído

- **M0 — Fundação** ✅ — commit `ef7bafa`.
  - Layout do repo, `go.mod`, `internal/platform/*`, `cmd/*`, Docker, CI,
    `scripts/db.sh`, guarda de SQL (`docs/sql-safety.md` + `scripts/check-sql.sh`),
    ADRs 0001–0004.

- **M1 — Schema + RLS + Auditoria** ✅ — (a commitar)
  - ADR-0005 (auditoria em 2 camadas) e ADR-0006 (colunas padrão + soft delete).
  - `postgres.WithTenantTx`: GUCs `app.device_id` e `app.request_id` (opcionais,
    alimentam a auditoria); novos campos em `TenantContext`.
  - Migrations:
    - `00002_iam.sql` — `iam.users/devices/sessions/refresh_tokens/password_reset_tokens/invitations`
      (globais, sem RLS; índices e uniques parciais).
    - `00003_app_org_permissions.sql` — `app.organizations`, `app.roles`,
      `app.organization_memberships`, `app.role_permissions`,
      `app.user_permission_overrides` (colunas padrão + trigger `app.set_row_defaults`);
      referência global `app.permission_catalog`, `app.role_templates`,
      `app.role_template_permissions` (sem escrita pelo `servory_app`);
      funções `app.current_org()` / `app.current_actor()`.
    - `00004_rls.sql` — `ENABLE`+`FORCE` RLS + policies de isolamento; policy
      dupla de `organization_memberships` (org OU user) para o login.
    - `00005_audit.sql` — `audit.row_history` (trigger genérica `audit.capture_row_change`,
      uma linha por coluna alterada), `audit.audit_events` + `audit.log_event(...)`,
      barreira append-only (`audit.deny_mutation` em UPDATE/DELETE/TRUNCATE).
    - `00006_seed_permissions.sql` — catálogo de 51 permissões (spec §17.2) e
      templates admin/technician/viewer (idempotente).
  - `sqlc` funcional: `internal/db/queries/*.sql` (users, memberships, sessions,
    refresh_tokens, permissions, organizations) → `internal/db/*.gen`. `sqlc diff` no CI.
  - `internal/testsupport/testdb` — Env com pool `servory_app` real + pool owner
    para seed/asserção; aplica migrations e trunca iam/app entre testes.
  - `internal/security/rls_test.go` — 9 testes de isolamento (spec §26.1):
    consulta sem contexto = 0 linhas; A não vê dados de B; busca por UUID de B =
    not found; `WITH CHECK` barra insert/update cross-tenant; policy dupla de
    memberships; trigger de colunas padrão (version/`*_by`); `row_history`
    capturado; `audit.*` append-only; `log_event` preenche contexto.
  - Verificado localmente contra Postgres 16: `migrate up/down` completo × N,
    `go test -race ./...` (todos verdes), `go vet`, `staticcheck`, `check-sql`, `sqlc diff`.

- **M2 — Senha + Tokens** ✅ — (a commitar)
  - `internal/platform/passwords` — Argon2id (perfil `Default` 64MiB/t=3/p=4),
    `Hash`/`Verify`/`NeedsRehash`, PHC string, constant time. ADR-0007.
  - `internal/platform/tokens/access.go` — `Issuer` (JWT EdDSA sobre o `KeySet`):
    `Issue`/`Verify`, claims `iss/sub/sid/org/aud/iat/nbf/exp/permission_version`,
    valida método/emissor/audiência/expiração, resolve chave por `kid`, relógio
    injetável, `WithStrictDecoding`.
  - `internal/platform/tokens/opaque.go` — `NewOpaque` (256 bits CSPRNG),
    `HashOpaque` (SHA-256 hex), `EqualHash` (constant time).
  - `cmd/auth-api/deps.go` — `dependencies.AccessTokens *tokens.Issuer` montado a
    partir da config.
  - Testes: `passwords_test.go` (roundtrip, senha errada, PHC malformado, salt,
    rehash) e `tokens/{access,opaque}_test.go` (roundtrip, expirado, audiência/
    emissor errados, assinatura adulterada, kid desconhecido, rotação de kid) —
    spec §26.3. Deps `golang.org/x/crypto` e `golang-jwt/jwt/v5` promovidas.

- **M3 — Login / Refresh / Revogação** ✅ — (a commitar)
  - `internal/iam` — serviço de identidade: `Login` (normaliza e-mail, rate limit,
    `passwords.Verify` + rehash, resolve org ativa, cria device/sessão, emite
    par), `Refresh` (rotação + **detecção de reuso** → revoga família **e**
    sessão), `Logout`/`LogoutAll`, `ListSessions`/`RevokeSession`, `Me`,
    `ForgotPassword`/`ResetPassword`. ADR-0008.
  - `internal/iam/middleware.go` — `Authenticator` (verifica JWT + sessão via
    Valkey com fallback Postgres) injeta `Principal` no contexto.
  - `internal/iam/http.go` — handlers `/v1/auth/{login,refresh,logout,logout-all,
    password/forgot,password/reset,sessions,sessions/{id}}` + `/v1/me`, montados
    por `deps.IAM.Routes`.
  - `internal/platform/mail` — Sender console/smtp (Mailpit); postmark fica p/ M6.
  - `internal/platform/tokens` — claim `did` + `Issuer.TTL()`.
  - `internal/platform/valkey` — `Incr` (rate limiting).
  - Novas queries sqlc: `devices.sql`, `password_reset_tokens.sql`, `GetRole`.
  - Testes: `internal/iam/iam_test.go` (15 casos, spec §26.3) — login ok/errado/
    desconhecido/inativo/sem-org, refresh rotaciona, reuso revoga família+sessão,
    refresh pós-logout/expirado, list/revoke sessão, revogar sessão alheia = 404,
    `Me`, reset revoga sessões + troca senha + token de uso único, forgot silencioso.
  - Smoke test manual contra o compose: login → /me → refresh → reuso (401 +
    sessão revogada via cache Valkey) confirmados ponta a ponta.

- **M4 — Organizações / Usuários / Convites** ✅ — (a commitar)
  - `internal/permissions`: `Resolver` (precedência §17.3 — exceções do usuário
    vencem o perfil; sem cache ainda), `Authorize(tc, key, fn)` (checa + age na
    mesma tx); `Service` para catálogo/perfis/exceções: `GET /v1/permissions`,
    `GET/POST /v1/roles`, `GET/PATCH/DELETE /v1/roles/{id}`,
    `PUT /v1/roles/{id}/permissions`, `GET/PUT /v1/users/{id}/permission-overrides`.
    Bumps de `permission_version` por perfil/usuário. ADR-0009.
  - `internal/organizations`: `GET/PATCH /v1/organization` (optimistic lock por
    `version`), `GET /v1/users`, `PATCH /v1/users/{id}`, `DELETE /v1/users/{id}/membership`
    (salvaguarda de último admin), `GET/POST /v1/users/invitations`,
    `DELETE /v1/users/invitations/{id}`. `Bootstrap` (org + materializa perfis dos
    templates + admin).
  - `internal/iam`: `AcceptInvitation` (`POST /v1/auth/invitations/accept` — senha
    sempre exigida; e-mail novo cria conta, existente autentica; devolve par de
    tokens). Helper `establishSession` extraído de `Login`.
  - `cmd/auth-api bootstrap --org --email [--name] [--password]` implementado.
  - Novas queries sqlc (memberships/roles/overrides/invitations); `testdb` agora
    serializa os testes de integração com `pg_advisory_lock` (pacotes rodam em
    paralelo sobre o mesmo banco).
  - Testes: `internal/organizations/m4_test.go` (bootstrap, precedência de
    permissões, convite de e-mail novo + uso único, optimistic lock, forbidden
    p/ não-admin, isolamento de membros entre orgs). Smoke manual: bootstrap →
    login → /organization → /roles → POST invitation.

- **M5 — Motor de permissões: cache + campo a campo** ✅ — (a commitar)
  - `permissions.Resolver`: cache no Valkey chaveado pelo `permission_version`
    **do banco** (não do token) → bump invalida na hora; degrada para Postgres
    sem Valkey. `NewResolver(pg, cache)`.
  - `permissions/fieldmask.go`: `CanReadField`/`CanWriteField`, `FilterReadable`,
    `UnauthorizedWrites` (campo fora do catálogo = negado, spec §17.4). O mapa
    `fields` fica com os módulos de negócio (M+).
  - `GET /v1/me/permissions` (`{permissions, permission_version}`) — servido pelo
    pacote `permissions` para evitar ciclo com `iam`.
  - Hardening: startup tolerante ao Valkey (spec §20; `valkey.Connect` com
    timeout curto, `deps` segue com `cache=nil`, `/readyz` só lista deps que
    subiram); `httpx.LimitBody(1MiB)` + `middleware.Timeout(20s)` + timeouts do
    `http.Server`; `mail.headerSafe` (CR/LF); `/readyz` não vaza `err.Error()`.
  - ADR-0010. Testes: `internal/permissions/permissions_test.go` (§26.2).

- **M6 — Rate limiting · fila de e-mail · auditoria · OpenAPI** ✅ — (a commitar)
  - `httpx.RateLimitByIP` — teto global por IP no Valkey (`RATE_LIMIT_PER_IP`/
    `_WINDOW`), 429 + `Retry-After`, degrada sem Valkey.
  - `internal/mailq` + migration `00007` (`iam.email_outbox`): `MAIL_ASYNC=true`
    faz os handlers enfileirarem; o `worker` entrega (`FOR UPDATE SKIP LOCKED`,
    backoff, `maxAttempts=6`). Tira o timing side-channel do `forgot`.
  - `audit.purge_older_than(interval)` (`SECURITY DEFINER`, GUC `audit.allow_purge`
    como única exceção à barreira append-only); `worker` expurga a cada 6h se
    `AUDIT_RETENTION > 0`.
  - `internal/audit`: `GET /v1/audit` (cursor keyset, permissão `audit.read`),
    `GET /v1/audit/row-history`.
  - `openapi/openapi.yaml` reescrito; `cmd/auth-api/routes_test.go` compara YAML ×
    rotas reais (`chi.Walk`), falha nos dois sentidos.
  - Dívida fechada: `/v1/me` recusa membership inativo; `valkey.Connect` falha
    rápido (`MaxRetries: -1`).
  - ADR-0011. Testes: `mailq_test.go`, `audit_test.go`, `httpx/ratelimit_test.go`,
    `routes_test.go`. Smoke: convite async → outbox → worker entrega → Mailpit;
    `/v1/audit` paginado; rate limit 429.

## Decisões tomadas

- A/B/C (2026-09-03): acatadas e implementadas no M1.
  - **A** — auditoria em 2 camadas → **ADR-0005**.
  - **B** — colunas padrão + soft delete em `app.*` → **ADR-0006**.
  - **C** — banco de teste: no M1 usa transação real do `servory_app` + `TRUNCATE`
    pelo owner entre testes (não precisou de clone de template nem testcontainers;
    reavaliar quando as tabelas de negócio crescerem).
- `iam.invitations.role_id` sem FK física para `app.roles` (evita ciclo de schema
  iam→app na migration 00002); validação no serviço. Mesma abordagem dos `*_by`.
- `iam.sessions.organization_id`: coluna adicionada (não estava explícita na spec
  §16.3) para fixar a organização ativa da sessão (spec §14.2) — FK lógica.
- `app.service_orders.assigned_user_id` sem FK física para `iam.users` (mesmo
  motivo/abordagem de `iam.invitations.role_id` e das colunas `*_by`): a
  associação ativa é validada na camada de serviço (`ErrAssigneeNotMember`).
- **Organização ≠ Empresa ≠ Pessoa** (2026-09-04): a spec tratava org = empresa
  (`app.organizations.legal_name/tax_id`). Nova regra do produto:
  - **Organização** = conta/tenant (usuários, permissões, RLS). Segue com
    `legal_name`/`tax_id` (dados fiscais da conta), mas o **emitente** de laudo/
    orçamento/etiqueta é a **Empresa**.
  - **Empresa** (`app.companies`) = 0..N por org. `kind`: `legal` (PJ, CNPJ) ou
    `individual` (o próprio profissional sem empresa, ligado a uma pessoa via
    `person_user_id` — sem FK física p/ `iam.users`, CHECK amarra kind↔person).
    Modelar o autônomo como linha em `companies` dá um caminho único downstream
    (todo documento referencia `company_id`).
  - **Pessoa** (`iam.people`) = 1:1 com `iam.users`, **global** (uma pessoa em
    todas as orgs). No schema `iam` (sem RLS) para manter o núcleo de auth
    reusável; PII isolada de `iam.users`. Auto-criada no 1º `PATCH /v1/me/person`.
  - **Vínculo Pessoa↔Empresa** (`app.company_members`) = opcional, M:N dentro da
    org, `is_primary` (única primária por pessoa). Sem vínculo → o app pergunta
    qual empresa usar ao montar o documento (também opcional).
  - Vínculo Pessoa↔Organização já era `app.organization_memberships`.
- Banco `servicelog`/`servicelog_test` renomeado para `servory`/`servory_test`
  (2026-09-03) — `servory` é o nome da aplicação. DB único com schemas
  `iam`/`app`/`audit` (sem DB por serviço). Reuso futuro de auth+auditoria em
  outros apps: decisão adiada.
- Correção herdada do M0: `scripts/db.sh` usava `psql -c` com `:"db"` (o psql não
  interpola nesse modo) — trocado por heredoc + `format(%I)` + `\gexec`.
- `Makefile` agora faz `-include .env` e exporta as DSNs para os comandos de host
  (`make migrate`, `make keys`) funcionarem sem export manual.
- **M2** — ADR-0007 (parâmetros de senha e formato dos tokens): Argon2id
  64MiB/t=3/p=4, PHC string, rehash-on-login; access token via `golang-jwt/jwt/v5`
  EdDSA com `kid`/strict decoding; refresh token opaco 256 bits guardado como
  SHA-256. `.codex/` no `.gitignore`.

## Ambiente local (2026-09-03)

- `docker compose up -d postgres valkey mailpit` no ar; `initdb` criou os papéis.
- Bancos migrados até a versão 6: `servory` (dev) e `servory_test` (testes).
- `go test -race ./...` verde contra `servory_test` (exporte `TEST_POSTGRES_APP_DSN`
  e `TEST_POSTGRES_MIGRATION_DSN` apontando para ele).

## Aguardando você

- **Decisão de merge**: `feature/auth-foundation` está completa (M0–M6). Fazer
  o merge para `main` e abrir nova branch para o domínio de negócio.

## Dívida técnica e hardening (revisão pós-M4, 2026-09-03)

Nenhum item crítico (sem bypass de auth, SQLi, vazamento de segredo; RLS sólida e
testada). Classificados por quando resolver.

### Corrigido no M5 ✅

- [x] **Startup tolerante ao Valkey** — `valkey.Connect` com timeout curto;
  `deps` segue com `cache=nil`; `/readyz` só lista deps que subiram.
- [x] **Limite de corpo de requisição** — `httpx.LimitBody(1 MiB)` na pilha base.
- [x] **Timeouts do `http.Server`** — `Read/Write/IdleTimeout` + `middleware.Timeout(20s)`.
- [x] **`mail`: CR/LF em `From`/`To`/`Subject`** — `headerSafe`.
- [x] **`/readyz` não vaza `err.Error()`** — detalhe só no log.

### Revisão de segurança pós-M6 (2026-09-03) — corrigido ✅

Varredura completa de SQL injection e prompt injection. **Sem SQLi** (todo SQL
cru é literal + `$N`; sqlc no resto; único `EXECUTE format` de migration itera
array literal; scripts com allowlist + `format(%I)`). **Sem LLM/IA no código** →
prompt injection não se aplica; vetores adjacentes (headers SMTP, log forging,
`X-Request-Id`) já tratados.

- [x] **`/v1/audit/row-history` vazava história de org nula cross-tenant** —
  incluía `iam.users` (com `old/new` de `password_hash`) se o UUID fosse
  conhecido. Restringido a `schema=app` + match estrito de `organization_id`
  (nega org nula).
- [x] **X-Forwarded-For forjável burlava o rate limiting / falseava IP em
  log/auditoria** — `TRUST_PROXY` (default `false`); confia no header só atrás de
  proxy que o sobrescreve. `docker-compose.prod.yml` liga `TRUST_PROXY=true`.

### Notas de hardening (não bloqueiam o merge)

- [x] `audit.purge_older_than` é `EXECUTE` para `servory_app` (não há endpoint que
  a chame; um papel de worker dedicado seria mais limpo) — resolvido pelo
  hardening `ADR-0015`: `servory_worker` é o papel dedicado do worker
  (`EXECUTE` em função `SECURITY DEFINER` já é `PUBLIC` por padrão, nenhum
  grant novo necessário).
- [ ] Normalização de e-mail: só `ToLower`+`Trim`; sem IDNA/homoglifo.

### Corrigido no M6 ✅

- [x] **Rate limiting por IP** — `httpx.RateLimitByIP` (teto global do `/v1`),
  429 + `Retry-After`, degrada sem Valkey. (Bloqueio progressivo por conta fica
  para o hardening da Fase 7.)
- [x] **E-mail assíncrono** — `internal/mailq` + `iam.email_outbox`; `MAIL_ASYNC`.
  Tira o timing side-channel do `forgot`.
- [x] **OpenAPI** — reescrito; teste de drift `chi.Walk` × YAML em `routes_test.go`.
- [x] **Retenção de auditoria** — `audit.purge_older_than` + `AUDIT_RETENTION` no
  worker (mecanismo; política fica com a operação, spec §30).
- [x] `/v1/me` checa `membership.status`.

### Ainda pendente após o M6 (Fase 7 / hardening ou nova branch)

- [ ] Testes §26.1 restantes: "worker não processa evento com tenant incorreto",
  "cache nunca entrega dados de outro tenant" — dependem dos módulos de negócio.
- [ ] Retenção de tombstones (§19.6) — só faz sentido com tabelas de negócio.
- [ ] Bloqueio progressivo de login por conta; rate limit por rota.
- [ ] Particionar `audit.row_history` por mês se o volume exigir.
- [ ] `bootstrap`: hoje cria uma nova org a cada chamada (aceitável p/ multi-org).

### Oportunístico (corrigir quando tocar o código; sem marco fixo)

- [ ] Trava otimista em `SetRolePermissions` / `SetUserOverrides` — `app.roles`
  tem `version` mas não é usada; edições concorrentes = last-write-wins silencioso.
- [ ] TOCTOU da salvaguarda de último admin — `SELECT ... FOR UPDATE` na linha do
  papel dentro do `RemoveMember` (isolamento READ COMMITTED).
- [ ] Auditoria de edição de permissões: `delete-all` + loop de insert gera muitas
  linhas de `row_history`; usar insert em lote.
- [ ] Deduplicar o mapeamento erro→HTTP (`writeErr`/`toHTTP` em `iam`,
  `permissions`, `organizations`) num helper compartilhado.
- [ ] Camada de validação de request (e-mail, tamanho de senha, enums) — hoje cada
  handler faz parsing manual.
- [ ] `config.ForTest()` para reduzir boilerplate nos testes.
- [ ] Revisitar estratégia de teste (advisory lock serializa tudo) — voltar ao
  clone-de-template (Decisão C) quando a suíte crescer.

### Futuro (quando o `servicelog-api` for separado)

- [ ] Audiência do JWT: o auth-api hoje valida os próprios endpoints com
  `aud=servicelog-api`; revisar (audiência dedicada ou compartilhada).

## Próximos passos (pós-merge)

**Guia de integração:** `docs/GUIA-BACKEND-NEGOCIO.md` — como o `servicelog-api`
consome a fundação (Principal, `WithTenantTx`, `Resolver.Authorize`, máscara de
campo, auditoria), convenções de migration/sqlc/HTTP/teste, e a receita completa
de adicionar uma entidade de negócio de ponta a ponta.

1. `git push` (faltam commits desde M6) + merge `feature/auth-foundation` → `main`.
2. Nova branch + `cmd/servicelog-api` (verifica JWT com `tokens.LoadVerifyKeySet`,
   reusa `iam.Service.Authenticator`).
3. **Recomendação de sequência** (a ordem da spec Fase 2→3 é sugestão; o backend
   da Fase 3 está no caminho crítico):
   - fatia vertical fina: `internal/clients` CRUD completo (prova o padrão de
     domínio: RLS em dado real, motor de campo a campo em uso, auditoria);
   - depois `locations`, `equipment_types`, `equipments` no mesmo molde;
   - **em paralelo**: Flutter Fase 2 (login/storage/Drift/offline) contra
     `/v1/auth/*` + `/v1/me` que já existem.
4. Resolver as decisões §30 relevantes antes de ir fundo (cripto do SQLite;
   algoritmo do código textual do QR) — ver guia §8.
5. Ao ligar os módulos de negócio, fechar os testes §26.1 restantes
   ("worker não processa evento com tenant incorreto", "cache nunca entrega dados
   de outro tenant").
