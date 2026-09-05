# ADR-0022 — Layout de etiqueta avulsa/impressora térmica

- **Status:** aceito
- **Data:** 2026-09-05
- **Contexto da spec:** §10.3 ("modelos de impressão")

## Contexto

ADR-0016 entregou o PDF físico do lote de etiquetas só no layout "folha
A4 em grade" (3×6, 18 etiquetas/página) — pensado para imprimir um lote
inteiro de uma vez numa impressora comum e recortar. Ficou registrado como
fora de escopo o "modelo individual"/impressora térmica: quem tem uma
impressora de etiqueta dedicada (bobina contínua, 40-100mm de largura
típica) não quer uma folha A4 — quer um PDF de uma página por etiqueta, no
tamanho físico exato da bobina, sem grade nem margem de recorte (a própria
bobina já delimita a etiqueta).

## Decisão

`format` ganha um terceiro valor, `thermal`, ao lado dos já existentes
`full`/`compact` — continua uma única enumeração flat (não um layout × um
toggle de QR): `thermal` sempre inclui QR Code (é o caso de uso real —
identificar um equipamento por leitura rápida), no tamanho de bobina
60×40mm (medida comum de etiqueta de ativo/patrimônio em impressora
térmica; não há hoje um requisito de "escolher o tamanho da bobina" — se
surgir, é uma dimensão nova de configuração, não decidida agora).

### Reaproveita `drawLabel` (a etiqueta em si não muda) — só a página muda

O conteúdo de uma etiqueta (borda, QR, código, linhas de texto) já era uma
função pura parametrizada por retângulo (`drawLabel(pdf, tr, x, y, w, h,
code, format, infoLines)`) — plugar o layout térmico não precisou tocar
nela. `renderLabelSheet` vira um dispatcher fino: `format == "thermal"` vai
para `renderThermalLabels` (uma página por código, tamanho custom via
`fpdf.NewCustom`/`AddPageFormat`); os demais formatos continuam em
`renderLabelGrid` (a função original, só renomeada). Nenhuma duplicação de
lógica de desenho.

### `label_batch_pdf_jobs.format` CHECK ampliado, não uma coluna nova

`thermal` é só mais um valor aceito pela mesma coluna `format` (mesmo
enfileiramento, mesmo dispatcher `pdfjobs.LabelDispatcher`, mesma
permissão `label_batch.export`) — migration `00035` troca o `CHECK
(format IN ('full', 'compact'))` por um que inclui `'thermal'`. Não há
necessidade de nova permissão, nova fila ou novo endpoint.

## Consequências

- `internal/pdfjobs/labelrender.go`: `FormatThermal`; `renderLabelSheet`
  despacha para `renderThermalLabels` ou `renderLabelGrid` (esta última é
  a antiga `renderLabelSheet`, sem mudança de comportamento).
- `internal/labels/pdf.go`: `FormatThermal` aceito por `RequestBatchPDF`.
- `migrations/00035_label_thermal_format.sql`: amplia o `CHECK` de
  `format`.
- `openapi.yaml`: enum de `format` ganha `thermal` nos dois lugares
  (request de `POST /v1/qr-batches/{id}/pdf` e o schema do job).
- Testes: `TestRenderThermalLabels`/`TestRenderThermalLabelsEmpty`
  (unidade, `internal/pdfjobs`), `TestRequestBatchPDFThermal`
  (`internal/labels`), `TestLabelDispatcherThermalFormat` (pipeline
  completo contra blob store real, `internal/pdfjobs`).
- Fecha o último item de fora-de-escopo registrado pelo ADR-0016.
