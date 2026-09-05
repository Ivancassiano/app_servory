# ADR-0016 — PDF físico da etiqueta

- **Status:** aceito
- **Data:** 2026-09-04
- **Contexto da spec:** §9.1 ("Escolher formato" → "Gerar PDF"), §10 (modelos de impressão), §25 (PDFs pesados em background), §30 (tamanhos físicos das etiquetas — decisão aberta)

## Contexto

`labels.ExportBatch` (ADR-0013) já marca o lote como emitido e devolve os
códigos em JSON — mas nunca gerou o arquivo de impressão de verdade. A spec
pede QR Code + código + dados da empresa emissora (modelo completo, §10.1)
ou só código + empresa (modelo compacto, §10.2), numa folha A4.

## Decisão

### Reaproveita a infraestrutura de PDF existente — mesmo molde, dois papéis diferentes

Mesmo padrão do laudo de ordem de serviço (ADR-0012, migration 00022):
`internal/labels.RequestBatchPDF` só enfileira (`app.label_batch_pdf_jobs`,
molde idêntico a `service_order_pdf_jobs` — claim + backoff + no máximo um
job pendente por lote); um novo `pdfjobs.LabelDispatcher` (mesmo pacote
`internal/pdfjobs`, arquivo `labeljobs.go`) processa: lê os códigos do lote
sob RLS, renderiza (`labelrender.go`) e grava no blob store (ADR-0012).
`cmd/worker` ganha um terceiro `Loop`, ao lado do laudo e do e-mail.

**Só um lote já exportado pode gerar PDF** (`ErrBatchNotIssued` se
`status != 'issued'`) — mesma disciplina do laudo, que só libera PDF em
ordem `completed` (precondição de status, nunca uma mutação de lifecycle
embutida na geração). Reusa a permissão `label_batch.export` — gerar o
arquivo de impressão é parte de "exportar" um lote, não uma ação nova;
nenhuma migration de `permission_catalog`.

### Dois papéis, não um Dispatcher genérico

Cogitei generalizar `Dispatcher` para qualquer tipo de PDF (uma fila, um
`process` parametrizado). Descartado: os dois jobs têm formas de payload,
fonte de dados e regra de "o que é obrigatório" completamente diferentes
(um lê uma ordem completa com peças/fotos/assinatura; o outro só uma lista
de códigos + uma empresa opcional) — a generalização exigiria uma interface
por cima de dois modelos de dado que não têm nada em comum além de "vira um
PDF e vai pro blob store". Duas structs pequenas e paralelas (`Dispatcher`,
`LabelDispatcher`), cada uma com sua própria fila/claim/backoff, ficam mais
diretas de ler do que uma abstração genérica usada só duas vezes — mesmo
raciocínio do ADR-0015 para não compartilhar `servory_business`/`servory_worker`.

### Layout: só folha A4 em grade, nesta entrega

Spec §10.3 lista "etiqueta individual", "folha A4" e "impressora térmica
(evolução posterior)" como formatos iniciais. Implementei só a folha A4:
grade 3 colunas × 6 linhas (18 etiquetas/página), célula de 60×42mm com
margens de 10mm e vãos de 5mm — cabe numa A4 padrão com folga para corte.
"Etiqueta individual" (uma por página) fica para quando houver demanda real
por impressora dedicada de etiqueta — é um ajuste de layout no mesmo
renderizador, não uma decisão nova.

### `github.com/skip2/go-qrcode` para gerar a imagem do QR

Nenhuma biblioteca de QR Code já estava no projeto (`go-pdf/fpdf`, já usado
pelo laudo, só desenha PDF — não gera código de barras/QR). Critério do
spec §30 ("bibliotecas simples, maduras, testáveis, licença compatível com
produto comercial"): `skip2/go-qrcode` é MIT, API mínima
(`qrcode.Encode(texto, nível, tamanho) → PNG`), sem dependências externas —
gera o PNG em memória, embutido no PDF do mesmo jeito que fotos/assinatura
já são embutidas no laudo (`fpdf.RegisterImageOptionsReader` +
`ImageOptions`).

### Empresa emissora: parâmetro explícito, não uma cascata nova

O laudo resolve o emitente por cascata (`company_id` da ordem → empresa
primária do técnico → dados da Pessoa, `internal/pdfjobs/render.go`) porque
uma ordem sempre tem um responsável (quem criou/foi designado). Um lote de
etiquetas não tem essa relação — pode ser reservado para um técnico, uma
equipe ou nenhum dos dois. Em vez de inventar uma "empresa primária da
organização" (conceito que não existe hoje: `app.companies` não tem
`is_primary` no nível de organização, só por técnico via
`ListCompaniesForUser`), `RequestBatchPDF` recebe `company_id` opcional —
quem chama escolhe qual empresa aparece na etiqueta; omitido, a folha sai
sem o bloco de identificação (mesma degradação graciosa do laudo quando
nenhuma das três fontes resolve um emitente).

`app.label_batch_pdf_jobs.company_id` usa `ON DELETE SET NULL` (não
`RESTRICT`, como `service_orders.company_id`) — é histórico de job, não um
registro de negócio vivo; não vale travar a exclusão de uma empresa por
causa de um PDF já gerado no passado.

### Sem "texto padrão" configurável por organização nesta entrega

Spec §10.3 também descreve um texto customizável por organização
(`Configurações → Etiquetas → Texto padrão`, com limite de linhas/caracteres
e pré-visualização). Isso é uma tela de configuração nova — um recurso à
parte de "gerar o PDF que já existe", fora do que foi pedido nesta entrega.
A etiqueta hoje mostra QR (se `full`) + código + as linhas fixas da empresa
(`emitterLines`, mesmo formato do laudo: nome, documento, telefone, e-mail,
endereço). Fica registrado como próximo passo natural quando o texto fixo
não for suficiente.

## Consequências

- `migrations/00029_label_batch_pdf.sql`: tabela `app.label_batch_pdf_jobs`
  (sem RLS, mesmo padrão de `service_order_pdf_jobs`/`iam.email_outbox` —
  infraestrutura, o worker escaneia todas as organizações).
- `internal/labels/pdf.go`: `RequestBatchPDF`/`BatchPDFStatus`/
  `BatchPDFDownloadURL`, molde `serviceorders/pdf.go`. `labels.Service`
  ganha um `*blob.Store` opcional (`New` mudou de assinatura — 4 chamadores
  atualizados: `cmd/servicelog-api/deps.go` e os testes).
- `internal/pdfjobs/labelrender.go` + `labeljobs.go`: renderização pura
  (testável sem banco/blob) + `LabelDispatcher` (claim + backoff, molde
  `Dispatcher`). `cmd/worker/main.go` ganha um terceiro `Loop`.
- Rotas novas: `GET/POST /v1/qr-batches/{id}/pdf`,
  `GET /v1/qr-batches/{id}/pdf/download` — `openapi/openapi.yaml` atualizado
  (schema `LabelBatchPDFStatus`, molde `ServiceOrderPDFStatus`).
- Nova dependência direta: `github.com/skip2/go-qrcode` (MIT).
- Verificado ao vivo (não só suíte de testes): `servicelog-api`/`worker`
  reais processando um lote de ponta a ponta — criar lote, exportar, pedir
  PDF, worker gera, download é um PDF de verdade com QR legível.
- **Fora do escopo desta entrega**: layout "etiqueta individual"/impressora
  térmica; texto padrão configurável por organização (spec §10.3).

**2026-09-05:** layout de etiqueta avulsa/impressora térmica implementado —
ver `ADR-0022`. Texto configurável por organização já tinha sido resolvido
antes via modelos de etiqueta (`ADR-0017`).
