# ADR-0013 — Etiquetas / QR Codes: vínculo polimórfico, código textual e escopo do MVP

- **Status:** aceito
- **Data:** 2026-09-04
- **Contexto da spec:** §8–§12, §17.2/§17.4 (permissões já seedadas), §21, §22.6

## Contexto

Uma etiqueta (QR Code) identifica cliente, local **ou** equipamento — nunca mais
de um. A spec (§21, tabela `qr_codes`) pede explicitamente a decisão em ADR:
"O vínculo polimórfico precisa ser validado na camada de serviço e protegido
por constraints/índices adequados. Como alternativa mais rigorosa, criar
tabelas de vínculo específicas por tipo."

O catálogo de permissões (`label.*`, `label_batch.*`) e os templates de perfil
já foram seedados na migration 00006, antecipando este módulo — não é preciso
nova migration de permissões.

## Decisão

### Vínculo polimórfico: três colunas nulláveis + `CHECK`, não uma tabela por tipo

`app.qr_codes` ganha `client_id`, `location_id` e `equipment_id` (nulláveis),
cada uma com **FK composta real** para `(organization_id, id)` da tabela
correspondente — não um par `entity_type text + entity_id uuid` solto. Um
`CHECK` garante no máximo uma preenchida, e só quando `status` alcançou
`assigned` (ver máquina de estados). Índices únicos parciais (um por coluna)
garantem **no máximo um código `assigned` por entidade** (spec §8.8) no nível
do banco, não só na aplicação.

Rejeitada a alternativa "mais rigorosa" da própria spec (tabela de vínculo
`qr_assignments` separada, com FK composta type-safe por tipo): o ganho de
rigor é marginal frente às 3 colunas + FK direta (que já dá integridade real,
constraint `CHECK` e índice), e uma tabela de vínculo à parte obrigaria join
extra em toda leitura do código sem eliminar a necessidade do `CHECK` de
cardinalidade (ainda seria preciso garantir "no máximo um tipo" na tabela de
vínculo). Índices/constraints diretos na própria linha do código são mais
simples de auditar e de sincronizar depois (spec §19).

O histórico de vínculo **não é apagado**: quando um código é desativado ou
substituído, a coluna de entidade (`client_id`/`location_id`/`equipment_id`)
continua preenchida — só o `status` muda. Isso preserva "o histórico deverá
registrar o código rejeitado e o novo código" (spec §12.5) sem tabela extra.

### Código textual: base32 sem ambíguos + dígito verificador

Fecha a decisão adiada em `docs/GUIA-BACKEND-NEGOCIO.md` §8 ("Algoritmo e
tamanho do código textual do QR"). Alfabeto de 32 símbolos —
`23456789ABCDEFGHJKLMNPQRSTUVWXYZ` — exclui `0/O` e `1/I` (spec §8.2). 16
caracteres de payload aleatório (`crypto/rand`, ~80 bits de entropia — nunca
derivado de sequence) + 1 caractere verificador (soma ponderada mod 32),
formatados em 4 grupos de 4 com prefixo `SL-`:
`SL-XXXX-XXXX-XXXX-XXXX-C`. Normalização na entrada: maiúsculas, remove
espaços/hífens antes de validar (spec §8.6). `public_code` é `UNIQUE` na
tabela; posse do código nunca concede acesso — toda operação exige o Bearer
token da organização (spec §8.2 "não conceder acesso por conhecimento do
código").

### Máquina de estados (subconjunto do §8.9 implementado agora)

`available → reserved → issued → assigned → {deactivated | replaced}`, mais
`lost` (a partir de `available`/`reserved`/`issued`, nunca de `assigned` — um
código já colado no equipamento não "perde-se" por marcação de lote).
`CONFLICT` e `PENDING_SYNC` **não são estados persistidos do código**:

- Uma tentativa de associação a um código já `assigned` nunca muda o código
  vencedor — só é registrada em `app.qr_assignment_attempts` (log,
  append-only pela aplicação) com `result = 'conflict'`. A regra "primeira
  confirmação no servidor vence" (spec §12.1) é aplicada com um
  `UPDATE ... WHERE status IN ('available','reserved')` — a cláusula `WHERE`
  é a trava de concorrência: se duas requisições disputarem o mesmo código,
  o banco serializa e só uma linha é afetada, sem precisar de `version`
  explícito nem lock manual.
- `PENDING_SYNC` é estado de **dispositivo offline** (spec §11.3) — só faz
  sentido quando o motor de sincronização (spec §19) existir. Adiado.

### Fora do escopo desta entrega (registrado para não reabrir a decisão à toa)

- **Sinalizar `REPLACEMENT_REQUIRED` nas entidades-alvo** (spec §12.4 —
  pendência visível na tela inicial, no registro, na sincronização e na
  próxima ordem). Isso é orquestração de UX do app Flutter sobre o resultado
  de `assign`/`replace` (`409` com o código do erro já é suficiente para o
  app decidir o que mostrar); não justifica colunas novas em
  `clients`/`locations`/`equipments` agora.
- **Modelos de impressão e geração do PDF físico da etiqueta** (spec §10).
  `POST /v1/qr-batches/{id}/export` marca o lote como emitido e devolve os
  códigos; renderizar o PDF do papel (QR + texto + logo) fica para quando a
  Fase 4/5 tratar de templates — a infraestrutura de PDF assíncrono já existe
  (`internal/pdfjobs`) e deve ser reaproveitada then.
- **Reimpressão com motivo obrigatório e aviso de destruir cópia antiga**
  (spec §9.3). `export` incrementa um contador e é sempre permitido; a
  confirmação explícita e o texto de aviso são responsabilidade do cliente
  antes de chamar o endpoint de novo. Evento de auditoria registra quem e
  quando, o que já dá rastreabilidade.
- **Perda de intervalo específico de etiquetas dentro de um lote** (spec
  §9.4 menciona "lote OU intervalo"). Implementado só o lote inteiro; um
  código isolado ainda pode ser desativado individualmente via
  `POST /v1/qr-codes/{id}/deactivate`.
- **Criação de código offline** (spec §11.4). Depende do motor de
  sincronização (spec §19) para reconciliar identificadores gerados no
  dispositivo.

## Alternativas consideradas

- **Tabela de vínculo `qr_assignments` por tipo** — ver acima; rejeitada por
  não eliminar a necessidade do `CHECK` de cardinalidade e adicionar join sem
  ganho de integridade proporcional.
- **`entity_type text + entity_id uuid` sem FK física** — mais flexível para
  adicionar um quarto tipo de entidade no futuro, mas abre mão de integridade
  referencial real (um `entity_id` "órfão" só seria pego em runtime). Rejeitada
  — o custo de adicionar uma quarta coluna no futuro é menor que o risco de
  dado inconsistente hoje.
- **`version` explícito para resolver conflito de `assign`** — desnecessário;
  o `WHERE status IN (...)` já serializa a primeira confirmação (ver acima) e
  evita expor `version` numa operação que semanticamente não é "editar o
  código", é "reivindicar" um código livre.

## Consequências

- `app.qr_codes`, `app.qr_batches`, `app.qr_assignment_attempts` — RLS FORCE
  + 7 colunas padrão (ADR-0006) nas duas primeiras; `qr_assignment_attempts`
  é log (só `organization_id` + `received_at_server`, sem soft delete/version
  — não é registro de negócio sincronizável).
- Toda leitura de "qual o código ativo desta entidade" filtra
  `status = 'assigned' AND <coluna>_id = $1` — os índices únicos parciais já
  cobrem essa consulta.
- Quando a Fase 4/5 endereçar impressão e sincronização, revisar este ADR
  para: (a) template/PDF de etiqueta, (b) `PENDING_SYNC` e criação offline,
  (c) sinalização de pendência nas entidades-alvo.
