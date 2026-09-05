# ADR-0012 — Armazenamento de objetos (S3-compatível / MinIO)

- **Status:** aceito
- **Data:** 2026-09-04
- **Contexto da spec:** §13.3, §14.2, §19.7, §26.4, §30

## Contexto

As próximas entregas de ordens de serviço — fotos antes/depois, assinatura do
cliente renderizada e o PDF do laudo — precisam guardar arquivos binários. A spec
(§13.3, §30) é explícita: **não guardar fotos grandes no PostgreSQL**; usar uma
**interface compatível com S3**, deixando a implementação concreta como decisão
de infraestrutura.

O deploy é uma VPS única, sem orquestrador (ADR-0001, ADR-0002). Não há
dependência de nuvem hoje e o piloto é com uma organização.

## Decisão

### Serviço e biblioteca

- **MinIO** como implementação padrão (S3-compatível, um binário, roda no mesmo
  compose da VPS). Migração para S3 gerenciado (AWS/Cloudflare R2/…) é só troca de
  config — `S3_ENDPOINT` vazio usa o S3 da AWS.
- Cliente Go: **`github.com/minio/minio-go/v7`** — puro Go, S3 v4, sem o peso do
  `aws-sdk-go-v2`. Uma lib serve para MinIO e para qualquer S3.
- `internal/platform/blob` — fachada fina (`Put`/`Get`/`Stat`/`Delete`/
  `PresignGet`/`Ping`). O resto do código nunca fala S3 direto.

### Bucket, chaves e isolamento (§14.2)

- **Um bucket** (`servory`), **prefixo lógico por organização**. Toda chave passa
  por `blob.Key(orgID, parts...)` → `org/{organization_id}/…`. Bucket por org
  seria mais isolado, mas multiplica a administração sem ganho real no MVP (o
  acesso já é mediado pela API, que resolve o `organization_id` da sessão).
- Layout: `org/{org}/service-orders/{so}/photos/{blob_id}`,
  `.../signatures/{blob_id}`, `.../pdf/{emissao}.pdf`.
- Bucket **privado**. Nada é servido publicamente.

### Metadados no Postgres, bytes no store (§19.7)

- Cada tipo de anexo tem uma tabela `app.*` (ex.: `service_order_photos`,
  `service_order_signatures`) com `blob_key`, `content_type`, `size_bytes`,
  `sha256`, legenda/rótulo + as 7 colunas padrão + RLS + auditoria. O store guarda
  só o conteúdo.
- **SHA-256** de cada arquivo é gravado (integridade e dedup técnica, §19.7).
- Apagar o anexo é soft-delete na linha; o objeto no store é removido pelo worker
  (ou fica como lixo tolerável até um GC). O tombstone da linha atende a sync.

### Upload e download

- **Download**: sempre por **URL assinada e temporária** (`PresignGet`,
  `S3_PRESIGN_TTL`, default 15 min — spec §26.4). A API responde
  `{ "url": "…", "expires_in": 900 }`; o cliente baixa direto do store.
- **Upload (MVP)**: `multipart/form-data` **através da API** — ela valida
  tamanho e content-type, calcula o SHA-256, grava no store e cria a linha de
  metadados numa transação. Simples e com validação no servidor.
- **Upload retomável / presigned PUT** (spec §19.7) fica para depois — otimização
  para arquivos grandes em rede ruim; o contrato de metadados não muda.

### Degradação (spec §20)

- Como o Valkey: o store é **opcional no boot**. Se `S3_BUCKET` não está
  configurado ou o MinIO não responde, `deps.Blob = nil`, `/readyz` reporta
  `blob: error` e **só os endpoints de anexo** respondem `503`. O resto da API
  (cadastros, ordens, auditoria) funciona.

### Config

`S3_ENDPOINT` (vazio = AWS), `S3_REGION`, `S3_BUCKET`, `S3_ACCESS_KEY`,
`S3_SECRET_KEY`, `S3_USE_SSL`, `S3_PRESIGN_TTL`. Injetado no `servicelog-api`
(anexos) e, quando o PDF entrar, no `worker`.

## Alternativas consideradas

- **Guardar no PostgreSQL (`bytea` / Large Objects)** — contraria a spec §30,
  incha o banco e os backups, e não escala para fotos. Rejeitado.
- **`aws-sdk-go-v2`** — mais completo, porém árvore de dependências grande para o
  que precisamos; `minio-go` cobre MinIO + S3 com uma fração do peso.
- **Bucket por organização** — melhor isolamento físico, mas administração e
  limites de bucket viram problema com muitas orgs; o prefixo lógico + a API como
  guardiã bastam no MVP (reavaliar se algum tenant exigir bucket dedicado).
- **Disco local no container** — sem durabilidade real (o container é
  efêmero/rebuildável) e não migra para nuvem. MinIO com volume nomeado dá o
  mesmo custo operacional com um caminho de saída.
- **Servir arquivos pela própria API (streaming)** em vez de URL assinada —
  gasta banda e conexões do processo; a URL assinada é o padrão S3 e o que a spec
  §26.4 pede.

## Consequências

- Novo serviço `minio` no compose dev e prod, com volume `miniodata`. O bucket
  nasce sozinho na primeira conexão (`blob.Connect` faz `MakeBucket` se não
  existir) — sem container auxiliar de setup, sem "lixo" de container parado
  depois do `up`. `docker-compose.prod.yml` traz o MinIO ligado; trocar por S3
  gerenciado é remover o serviço e ajustar `S3_*`.
- `internal/platform/blob` + `config.Blob` + wiring no `servicelog-api`
  (`/readyz` ganha o check `blob`).
- As tabelas e endpoints de foto/assinatura/PDF nas próximas migrations herdam
  este contrato (metadados + `blob.Key` + presign).
- O `servory_business` (hardening, ADR futuro) também precisará das credenciais
  S3 — nada de `iam.*`, mas sim do store.
