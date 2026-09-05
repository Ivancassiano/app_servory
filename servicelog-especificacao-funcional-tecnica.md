# ServiceLog — Especificação Funcional e Técnica

**Versão:** 1.0  
**Data:** 03/09/2026  
**Status:** Documento inicial para implementação  
**Público:** Produto, UX, arquitetura e desenvolvimento  
**Stack principal:** Go, PostgreSQL, Flutter, SQLite/Drift e Valkey

---

## 1. Instruções para o agente de desenvolvimento

Este documento deve ser tratado como a fonte inicial de requisitos do ServiceLog.

Ao iniciar o desenvolvimento:

1. Não implementar todos os módulos simultaneamente.
2. Começar pela fundação técnica, multitenancy, autenticação e permissões.
3. Criar testes automatizados para isolamento entre organizações antes dos módulos de negócio.
4. Manter PostgreSQL como fonte oficial de dados.
5. Não confiar em `organization_id`, permissões ou identidade enviados livremente pelo cliente.
6. Não resolver conflitos de QR Code por mesclagem, transferência ou exclusão de dados.
7. Usar IDs que possam ser criados offline.
8. Manter o backend como autoridade final de autenticação, autorização e sincronização.
9. Registrar decisões técnicas adicionais em ADRs, sem modificar silenciosamente as regras deste documento.
10. Quando houver ambiguidade com impacto de produto, segurança ou perda de dados, interromper a implementação desse ponto e solicitar uma decisão.

### Primeira entrega esperada

A primeira entrega deve conter:

- estrutura do repositório;
- ambiente local com Docker Compose;
- PostgreSQL e Valkey;
- migrations versionadas;
- modelos de organização, usuário, associação e sessão;
- autenticação híbrida funcional;
- isolamento multitenant com RLS;
- mecanismo inicial de permissões;
- aplicação Flutter com login e armazenamento seguro de sessão;
- testes de isolamento entre organizações;
- documentação para executar o projeto localmente.

Não iniciar clientes, equipamentos e ordens de serviço antes de a fundação de segurança estar testada.

---

## 2. Visão do produto

O ServiceLog é um sistema de histórico de manutenção destinado a pequenas empresas e profissionais que instalam, inspecionam ou consertam equipamentos.

A pergunta central respondida pelo produto é:

> O que já foi feito neste equipamento, quando, por quem e com quais peças?

O produto deverá substituir históricos dispersos em papel, planilhas, WhatsApp, pastas de fotos e memória dos técnicos por um prontuário técnico permanente.

### Estrutura principal

```text
Organização prestadora
└── Cliente
    └── Local
        └── Equipamento
            └── Histórico de serviços
```

Exemplo:

```text
ClimaTech Manutenções
└── Hotel Roma
    └── Cozinha
        └── Ar-condicionado Daikin FTXM35
            ├── Instalação
            ├── Manutenção preventiva
            └── Troca do capacitor
```

### Organização, empresa e pessoa

Três entidades distintas, frequentemente confundidas:

```text
Usuário (login)  ──1:1──  Pessoa (CPF, telefone, registro profissional)
       │
       └── membro de ──►  Organização        (a conta: usuários, permissões, isolamento de dados)
                                │
                                ├── tem 0..N ──►  Empresa   ◄── emitente do laudo/orçamento/etiqueta
                                │
Pessoa ──vínculo opcional (0..N)──►  Empresa
```

- **Organização** é a conta contratante. Não é necessariamente uma empresa: pode
  agrupar sócios, filiais ou um único profissional. Controla usuários, perfis,
  permissões e o isolamento de dados (`organization_id` + RLS).
- **Empresa** é quem assina o documento — razão social, CNPJ, telefone, endereço,
  logo. Uma organização pode ter **zero, uma ou várias**. Dois tipos:
  - **pessoa jurídica** (`kind = legal`): CNPJ próprio;
  - **profissional autônomo** (`kind = individual`): uma pessoa que presta serviço
    sem empresa constituída; a "empresa" são os dados da própria pessoa.
- **Pessoa** são os dados pessoais do usuário (nome completo, CPF, telefone,
  registro em conselho). Vive junto do usuário (1:1) e é **global** — a mesma
  pessoa em todas as organizações de que participa.
- **Vínculo pessoa ↔ empresa** é **opcional** e muitos-para-muitos dentro da
  organização, com uma empresa **primária** por pessoa. Ao montar um laudo ou
  orçamento:
  - pessoa com **uma** empresa (ou uma primária) → usa essa;
  - pessoa com **várias** ou **nenhuma** → o app pergunta qual usar (também
    opcional); sem empresa, o emitente são os dados da Pessoa.

A ordem de criação não é fixa: um primeiro acesso pode criar a organização antes
de completar o cadastro pessoal, e a empresa pode ficar para depois.

### Proposta de valor

> Identifique um cliente, local ou equipamento por etiqueta e consulte seu histórico de forma rápida, inclusive durante atendimentos com conectividade limitada.

### Princípios do produto

- Simplicidade é parte do produto.
- O técnico deve registrar um serviço simples em poucos minutos.
- O sistema deve funcionar em campo e offline.
- Nenhum dado de negócio pode atravessar os limites de uma organização.
- O QR Code é um atalho; o código textual correspondente deve realizar a mesma função.
- Dados operacionais nunca devem ser alterados ou descartados automaticamente para resolver conflitos de etiquetas.

---

## 3. Objetivos do MVP

O MVP deverá oferecer:

1. Autenticação e sessões por dispositivo.
2. Organizações e usuários.
3. Perfis, permissões e exceções por usuário.
4. Cadastro de clientes.
5. Cadastro de locais.
6. Cadastro de equipamentos.
7. Ordens de serviço.
8. Histórico cronológico por equipamento.
9. Fotos, documentos e peças utilizadas.
10. QR Codes e códigos textuais.
11. Geração e atribuição de etiquetas.
12. Lotes de etiquetas pré-geradas.
13. Impressão e exportação de etiquetas.
14. Assinatura do cliente.
15. Relatório de atendimento em PDF.
16. Operação offline no aplicativo Flutter.
17. Sincronização segura e idempotente.
18. Auditoria das operações sensíveis.

### Fora do MVP

- Contabilidade.
- Emissão fiscal.
- Folha de pagamento.
- Gestão de frota.
- Roteirização avançada.
- CRM de vendas completo.
- Marketing.
- Estoque avançado.
- Inteligência artificial.
- Aplicação web administrativa completa.
- Acesso público aos dados por QR Code.
- Mesclagem automática de registros.

---

## 4. Plataformas

### Aplicação cliente

Flutter deverá ser usado para:

- Android;
- iOS;
- Windows;
- macOS;
- Linux, se houver demanda.

O MVP prioriza Android e desktop. O compartilhamento de código deve abranger interface, domínio, persistência local, permissões e sincronização sempre que for viável.

### Aplicação web

Não faz parte da primeira versão. A API deverá, entretanto, permanecer independente do Flutter para permitir uma futura interface web.

Uma aplicação web poderá ser útil posteriormente para:

- administração de usuários;
- configuração avançada de permissões;
- geração de lotes de etiquetas;
- relatórios;
- acesso sem instalação.

### Links das etiquetas

Mesmo sem aplicação web completa, o QR Code poderá conter um link HTTPS associado ao aplicativo. Quando não houver sessão válida, nenhuma informação de cliente, local ou equipamento será apresentada.

---

## 5. Perfis de usuário

### Administrador da organização

- Gerencia dados da empresa.
- Cadastra e desativa usuários.
- Define perfis e permissões.
- Gera e administra lotes de etiquetas.
- Visualiza todos os clientes e equipamentos permitidos.
- Resolve pendências de sincronização.
- Consulta auditoria.

### Técnico

- Consulta clientes, locais e equipamentos autorizados.
- Escaneia e digita códigos.
- Cadastra equipamentos conforme sua permissão.
- Abre, executa e finaliza ordens.
- Registra diagnóstico, peças, fotos e recomendações.
- Coleta assinatura.
- Trabalha offline.

### Visualizador

- Consulta os recursos permitidos.
- Não altera registros por padrão.

### Perfil personalizado

Uma organização poderá criar perfis adicionais combinando permissões. Exceções individuais poderão permitir ou negar ações e campos para um usuário específico.

---

## 6. Mapa de navegação

```text
ServiceLog
├── Login
│   ├── Recuperar senha
│   └── Primeiro acesso
│
├── Início
│   ├── Escanear etiqueta
│   ├── Digitar código
│   ├── Novo cliente
│   ├── Nova ordem
│   ├── Atividades recentes
│   └── Pendências de sincronização/etiquetas
│
├── Clientes
│   └── Cliente
│       ├── Dados
│       ├── Locais
│       ├── Equipamentos
│       ├── Ordens
│       ├── Documentos
│       └── Gerenciar etiqueta
│
├── Locais
│   └── Local
│       ├── Dados
│       ├── Equipamentos
│       ├── Ordens
│       └── Gerenciar etiqueta
│
├── Equipamentos
│   └── Equipamento
│       ├── Informações
│       ├── Histórico
│       ├── Fotos
│       ├── Documentos
│       ├── Peças utilizadas
│       ├── Recomendações
│       ├── Nova ordem
│       └── Gerenciar etiqueta
│
├── Ordens de serviço
│   └── Ordem
│       ├── Diagnóstico
│       ├── Serviço realizado
│       ├── Peças e materiais
│       ├── Fotos
│       ├── Recomendações
│       ├── Assinatura
│       └── PDF
│
└── Configurações
    ├── Empresa
    ├── Usuários
    ├── Perfis e permissões
    ├── Tipos de equipamento
    ├── Tipos de serviço
    ├── Etiquetas e modelos de impressão
    ├── Notificações
    ├── Segurança
    ├── Dispositivos e sessões
    └── Plano
```

### Navegação móvel sugerida

```text
[ Início ] [ Clientes ] [ QR/Code ] [ Ordens ] [ Mais ]
```

O botão central deverá oferecer:

```text
Identificar etiqueta
├── Escanear QR Code
└── Digitar código
```

---

## 7. Fluxos funcionais

### 7.1 Login

```text
E-mail + senha
↓
Validar usuário global
↓
Determinar organização ativa
↓
Criar sessão do dispositivo
↓
Emitir access token e refresh token
↓
Sincronizar permissões
↓
Tela inicial
```

O usuário não seleciona a organização durante o login.

### 7.2 Primeiro acesso

```text
Convite recebido
↓
Validar convite
↓
Definir senha
↓
Confirmar associação à organização
↓
Criar sessão
↓
Tela inicial
```

### 7.3 Cadastro de cliente

O cliente é **pessoa jurídica ou pessoa física** (`kind`), como a empresa
prestadora. Definido na criação, imutável depois.

Campos iniciais:

- tipo (jurídica / física);
- nome fantasia (PJ) ou nome (PF);
- razão social (PJ);
- documento fiscal (CNPJ ou CPF);
- telefone;
- e-mail;
- pessoa de contato (contato rápido — a lista completa fica em "contatos");
- observações.

**Contatos** — botão "incluir contato": vários por cliente, campos telefone
(obrigatório) e nome (opcional, quando aplicável), além de cargo, e-mail, flag
"é WhatsApp" e um marcador de contato principal.

Fluxo:

```text
Novo cliente
↓
Preencher dados autorizados
↓
Salvar
↓
Cliente criado
├── Adicionar local
├── Adicionar contato
├── Adicionar etiqueta
└── Concluir
```

### 7.4 Cadastro de local

Um cliente tem vários locais. Um local pode estar **dentro de outro local** —
quando o cliente é uma empresa com filiais, o local de nível superior é a filial
e os locais internos são departamentos (a hierarquia é livre: filial >
departamento > sub-departamento > …). Um departamento não precisa repetir o
endereço da filial — por isso tudo abaixo é opcional.

Campos:

- cliente (obrigatório);
- local pai (opcional — deixa o local dentro de outro, do mesmo cliente);
- nome do local;
- **endereço** (opcional, botão "inserir endereço"): CEP, logradouro, número,
  complemento, bairro, cidade, UF;
- pessoa de contato + telefone (contato rápido);
- **contatos** (opcional, botão "inserir contato"): vários por local — contato,
  telefone (com atalho para ligar no app), flag "é WhatsApp". Dispensável quando
  o cliente é pessoa física;
- instruções de acesso;
- observações.

Fluxo:

```text
Cliente
↓
Adicionar local  (opcionalmente dentro de outro local)
↓
Salvar
↓
Local criado
├── Adicionar sublocal (departamento)
├── Adicionar contato
├── Adicionar equipamento
├── Adicionar etiqueta
└── Concluir
```

Remover um local só é permitido quando ele não tem sublocais.

### 7.5 Cadastro de equipamento

Campos iniciais:

- cliente;
- local;
- tipo;
- nome ou identificação;
- marca;
- modelo;
- número de série;
- data de instalação;
- localização interna;
- foto principal;
- observações;
- manual ou documento.

Fluxo:

```text
Novo equipamento
↓
Preencher dados autorizados
↓
Salvar
↓
Equipamento criado
├── Adicionar etiqueta
├── Criar primeira ordem
├── Cadastrar outro equipamento
└── Concluir
```

O registro deve ser salvo antes de qualquer ação de QR Code. Uma falha de câmera, conexão ou impressão não poderá causar perda dos dados preenchidos.

### 7.6 Ordem de serviço

Uma ordem poderá ser criada pela tela inicial, cliente, local, equipamento ou leitura de etiqueta.

```text
Nova ordem
↓
Selecionar cliente
↓
Selecionar local
↓
Selecionar equipamento
↓
Informar motivo da visita
↓
Definir técnico
↓
Salvar como aberta
↓
Iniciar atendimento
↓
Diagnóstico
↓
Serviço realizado
↓
Peças e materiais
↓
Fotos antes/depois
↓
Recomendações
↓
Condição final
↓
Assinatura do cliente
↓
Finalizar
↓
Gerar PDF
```

A ordem poderá ser salva como rascunho em todas as etapas.

---

## 8. QR Codes, códigos e etiquetas

### 8.1 Conceito

Uma etiqueta pode identificar:

1. cliente;
2. local;
3. equipamento.

O tipo não precisa estar codificado de forma previsível no identificador. O servidor mantém a relação entre o código e o recurso.

### 8.2 Código textual

O código textual é a identidade funcional da etiqueta. O QR Code apenas facilita sua leitura.

Formato ilustrativo:

```text
SL-8K4P-7M2Q-C
```

Requisitos:

- não usar apenas a sequence do banco;
- usar identificador aleatório com entropia adequada;
- evitar caracteres ambíguos, como `O/0` e `I/1`;
- usar dígito ou caractere verificador;
- aceitar entrada sem separadores;
- normalizar letras para maiúsculas;
- ser único globalmente ou, no mínimo, possuir unicidade inequívoca no servidor;
- não conceder acesso por conhecimento do código.

O ID interno do banco pode ser UUID ou numérico. O código público não deve revelar IDs internos sequenciais.

### 8.3 Adicionar etiqueta

Depois de salvar cliente, local ou equipamento:

```text
Cadastro concluído
├── Adicionar etiqueta
└── Concluir
```

Ao escolher adicionar:

```text
Como deseja adicionar a etiqueta?

├── Usar etiqueta existente
│   ├── Escanear QR Code
│   └── Digitar código
│
└── Criar nova etiqueta
```

Na interface de campo, usar os textos:

- **Escanear etiqueta impressa** — use uma etiqueta livre que você já possui.
- **Criar nova etiqueta** — gere um código para imprimir agora ou posteriormente.

### 8.4 Atribuir etiqueta existente

```text
Registro já salvo
↓
Adicionar etiqueta
↓
Escanear QR ou digitar código
↓
Validar disponibilidade
↓
Exibir confirmação visual do destino
↓
Confirmar
↓
Etiqueta vinculada
```

A confirmação deverá apresentar:

- tipo do destino;
- cliente;
- local;
- equipamento, quando aplicável;
- foto, quando disponível;
- modelo e número de série;
- código da etiqueta.

### 8.5 Criar nova etiqueta

```text
Registro já salvo
↓
Criar nova etiqueta
↓
Gerar código
↓
Vincular automaticamente
↓
Visualizar
├── Imprimir
├── Baixar PDF
├── Compartilhar
└── Imprimir posteriormente
```

Não solicitar formato, papel ou impressora antes de criar o código. Essas escolhas pertencem à etapa de impressão.

### 8.6 Identificação por código

Todas as telas com leitura de câmera deverão oferecer:

```text
[ Escanear QR Code ]
[ Digitar código ]
```

A entrada manual deverá:

- inserir separadores visualmente;
- aceitar colagem;
- ignorar espaços;
- validar o caractere verificador;
- permitir retornar à câmera;
- informar erro sem revelar dados de outras organizações.

### 8.7 Tela aberta após a identificação

O tipo precisa ficar evidente:

```text
EQUIPAMENTO
Hotel Roma › Cozinha

Ar-condicionado Daikin
FTXM35 · Serial 3728173

[ Iniciar serviço ] [ Ver histórico ]
```

Para cliente e local, usar título e ações compatíveis. Isso evita que o técnico confunda um QR de local com um QR de equipamento.

### 8.8 Um QR ativo por registro

No MVP, cliente, local ou equipamento terá no máximo uma etiqueta ativa.

```text
Sem etiqueta:
[ Adicionar etiqueta ]

Com etiqueta:
[ Gerenciar etiqueta ]
```

Gerenciar etiqueta:

```text
Código atual
├── Visualizar
├── Baixar
├── Reimprimir
├── Substituir
└── Desativar
```

### 8.9 Estados verificáveis

Estados de etiqueta:

```text
AVAILABLE             livre
ISSUED                incluída em uma emissão/exportação
RESERVED              reservada para técnico/equipe/dispositivo
PENDING_SYNC          vinculada localmente e aguardando servidor
ASSIGNED              vínculo confirmado
CONFLICT              associação posterior recusada
DEACTIVATED           desativada
REPLACED              substituída
LOST                  perdida
```

Não usar `PRINTED` como verdade operacional. O sistema sabe que um arquivo foi gerado ou enviado à impressão, mas não consegue confirmar que a etiqueta física foi produzida.

---

## 9. Lotes de etiquetas

### 9.1 Geração

```text
Configurações
↓
Etiquetas
↓
Criar lote
↓
Informar quantidade
↓
Gerar códigos únicos
↓
Definir responsável
├── técnico
├── equipe
└── dispositivo
↓
Escolher formato
↓
Gerar PDF
```

Exemplo:

```text
Lote: 2026-004
Quantidade: 10
Responsável: Marco Bianchi
Status: emitido
```

O lote é uma unidade de rastreamento e reserva. Cada etiqueta continua tendo seu próprio código único.

### 9.2 O que o lote resolve

- rastreabilidade;
- distribuição física;
- reserva para trabalho offline;
- visualização de etiquetas ainda livres;
- invalidação de folhas perdidas;
- histórico de emissão e reimpressão.

O número do lote sozinho não impede duplicidade. O mesmo PDF pode ser impresso mais de uma vez. A prevenção depende de códigos únicos, responsável pelo lote, reserva no servidor e cópia sincronizada no dispositivo.

### 9.3 Reimpressão

Reimprimir etiquetas livres de um lote cria risco de duas cópias físicas do mesmo código.

Requisitos:

- exigir confirmação explícita;
- registrar usuário, data e motivo;
- incrementar o número da emissão;
- avisar que cópias anteriores precisam ser destruídas;
- oferecer como alternativa invalidar o lote e criar outro.

### 9.4 Perda de lote

Um administrador poderá marcar um lote ou intervalo de etiquetas como perdido. Códigos perdidos não podem receber novas associações.

---

## 10. Modelos de impressão

### 10.1 Modelo completo

```text
┌────────────────────────────┐
│         [QR CODE]          │
│                            │
│      SL-8K4P-7M2Q-C        │
│                            │
│ ClimaTech Manutenções Ltda │
│ CNPJ 12.345.678/0001-90    │
│ Tel. (11) 99999-9999       │
└────────────────────────────┘
```

### 10.2 Modelo compacto

```text
┌────────────────────────────┐
│      SL-8K4P-7M2Q-C        │
│                            │
│ ClimaTech Manutenções Ltda │
│ CNPJ 12.345.678/0001-90    │
│ Tel. (11) 99999-9999       │
└────────────────────────────┘
```

O modelo compacto funciona exclusivamente por digitação do código.

### 10.3 Texto personalizado

Configuração por organização:

```text
Configurações
└── Etiquetas
    └── Texto padrão
```

O texto:

- aceita múltiplas linhas;
- possui limite de linhas e caracteres;
- apresenta pré-visualização;
- pode ser alterado por emissão;
- não pode reduzir a área mínima ou margem de segurança do QR Code.

Formatos iniciais:

- QR Code + código + texto;
- código + texto;
- etiqueta individual;
- folha A4;
- formato de impressora térmica como evolução posterior.

---

## 11. Funcionamento offline das etiquetas

### 11.1 Princípio

Atribuições offline é permitido, mas uma etiqueta pré-impressa precisa estar previamente reservada e sincronizada no dispositivo.

### 11.2 Preparação

```text
Administrador cria lote online
↓
Servidor cria os códigos
↓
Lote é reservado para técnico/equipe/dispositivo
↓
Dispositivo sincroniza o lote
↓
Técnico leva as etiquetas físicas
```

### 11.3 Atribuição offline segura

```text
Salvar registro offline
↓
Adicionar etiqueta
↓
Escanear ou digitar
↓
Validar código no lote local
↓
Código reservado para o contexto atual?
├── Sim → vincular localmente e marcar PENDING_SYNC
└── Não → não confirmar; solicitar conexão
```

Uma etiqueta não presente no inventário offline autorizado não pode ser confirmada como associada. O registro de negócio continua salvo sem etiqueta.

### 11.4 Criação de etiqueta offline

`Criar nova etiqueta` pode funcionar offline se o aplicativo gerar um identificador aleatório com entropia suficiente.

```text
Criar código local
↓
Vincular ao registro local
↓
Adicionar criação e vínculo à outbox
↓
Sincronizar posteriormente
```

Sequences centralizadas do PostgreSQL não devem ser usadas como identidade de registros criados offline.

---

## 12. Regra definitiva para conflitos de etiquetas

### 12.1 Precedência

> A primeira associação confirmada pelo servidor permanece válida.

Uma associação posterior do mesmo código é recusada.

O horário local do dispositivo não decide a precedência, porque pode estar incorreto ou manipulado. A ordem de confirmação no servidor é a referência.

### 12.2 Proibições

Um conflito de etiqueta nunca poderá:

- mesclar clientes;
- mesclar locais;
- mesclar equipamentos;
- substituir dados de um registro;
- excluir histórico;
- transferir automaticamente uma etiqueta;
- escolher automaticamente qual registro conservar.

### 12.3 Resultado

```text
Primeira associação confirmada
→ permanece ASSIGNED

Associação posterior
→ vínculo rejeitado
→ dados preservados
→ registro marcado como REPLACEMENT_REQUIRED
```

O segundo registro continua permitindo operações normais. Apenas aquela etiqueta não o identifica.

### 12.4 Experiência do usuário

```text
Esta etiqueta já está em uso.

O código não pode ser utilizado neste registro.
Todos os dados cadastrados foram preservados.

Será necessário substituir a etiqueta física quando possível.

[ Substituir agora ] [ Fazer depois ]
```

`Fazer depois` cria uma pendência visível:

- na tela inicial;
- no registro afetado;
- nas pendências de sincronização;
- na próxima ordem de serviço relacionada.

### 12.5 Substituição

```text
Registro com substituição pendente
↓
Substituir etiqueta
├── escanear etiqueta existente
├── digitar código
└── criar nova etiqueta
↓
Validar novo código
↓
Confirmar
↓
Pendência resolvida
```

O histórico deverá registrar o código rejeitado e o novo código, sem alterar dados do cliente, local, equipamento ou ordens.

---

## 13. Arquitetura técnica

```text
Flutter Mobile/Desktop
├── SQLite/Drift
├── Outbox de sincronização
├── armazenamento seguro
└── UI orientada por permissões
          │
          ├── Identity/Auth API — Go
          │   ├── login
          │   ├── refresh
          │   ├── revogação
          │   └── recuperação de senha
          │
          └── ServiceLog API — Go
              ├── organizações e permissões
              ├── clientes/locais/equipamentos
              ├── ordens
              ├── etiquetas
              └── sincronização
                       │
              ┌────────┼─────────┐
              │        │         │
         PostgreSQL  Valkey  Object storage
         fonte       cache    fotos/PDFs
         oficial
```

### 13.1 Componentes de execução

- `auth-api`: identidade, credenciais, sessões e tokens.
- `servicelog-api`: regras de negócio, autorização e sincronização.
- `worker`: PDFs, notificações, limpeza e tarefas assíncronas.
- `postgres`: fonte oficial e auditoria.
- `valkey`: cache e dados temporários.
- `object-storage`: arquivos, fotos, assinaturas renderizadas e PDFs.

O armazenamento de objetos deverá usar uma interface compatível com S3. A implementação concreta permanece uma decisão de infraestrutura. Não armazenar fotos grandes diretamente em PostgreSQL.

### 13.2 Estrutura Go sugerido

```text
cmd/
├── auth-api/
├── servicelog-api/
└── worker/

internal/
├── iam/
├── organizations/
├── permissions/
├── clients/
├── locations/
├── equipments/
├── serviceorders/
├── qrcodes/
├── labels/
├── sync/
├── files/
├── audit/
└── platform/
    ├── postgres/
    ├── valkey/
    ├── tokens/
    └── objectstorage/

migrations/
openapi/
deploy/
```

Começar como um monorepo e manter módulos com fronteiras claras. Não introduzir Kubernetes ou uma arquitetura extensa de microsserviços no MVP.

---

## 14. Multitenancy

### 14.1 Modelo

Um cluster/banco PostgreSQL compartilhado, tabelas compartilhadas e `organization_id` em todos os dados pertencentes a uma organização.

Não criar um schema completo ou banco separado para cada empresa no MVP.

### 14.2 Regras

- O `organization_id` ativo é derivado da sessão/token.
- O aplicativo não define livremente o tenant de uma operação.
- Toda consulta e escrita é limitada ao tenant.
- Chaves estrangeiras incluem a organização quando houver risco de relação cruzada.
- Chaves de cache incluem a organização.
- Arquivos usam prefixo ou bucket lógico por organização.
- Logs e auditoria registram a organização.
- Jobs em background executam com contexto explícito de organização.

### 14.3 PostgreSQL Row-Level Security

Usar RLS como defesa adicional:

```sql
ALTER TABLE app.equipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.equipments FORCE ROW LEVEL SECURITY;

CREATE POLICY equipment_tenant_isolation
ON app.equipments
USING (
  organization_id = current_setting('app.organization_id')::uuid
)
WITH CHECK (
  organization_id = current_setting('app.organization_id')::uuid
);
```

Por transação:

```sql
SET LOCAL app.organization_id = '<organization_uuid>';
SET LOCAL app.user_id = '<user_uuid>';
```

O papel PostgreSQL utilizado pela aplicação:

- não é superusuário;
- não possui `BYPASSRLS`;
- não é proprietário das tabelas protegidas;
- não pode desabilitar políticas.

RLS não substitui testes de isolamento nem autorização no código.

---

## 15. Identidade, organizações e login

### 15.1 Usuário global

O usuário possui identidade única, normalmente pelo e-mail normalizado.

```text
iam.users
- id UUID
- email
- normalized_email UNIQUE
- password_hash
- status
- token_version
- created_at
- updated_at
```

### 15.2 Associação

```text
iam.organization_memberships
- organization_id
- user_id
- role_id
- status
- is_default
- permission_version
- created_at
```

### 15.3 Login sem seleção de organização

```text
E-mail e senha
↓
Usuário global
↓
Uma organização ativa?
├── Sim → utilizar automaticamente
└── Mais de uma → utilizar a organização padrão
```

No MVP poderá ser imposta a regra de uma única organização ativa por usuário. O modelo deve aceitar múltiplas associações para evolução futura.

Caso exista troca de organização futuramente, ela acontecerá depois do login e emitirá um novo access token. O usuário não selecionará a organização na tela de autenticação.

### 15.4 Convites

- Convite contém organização, e-mail, perfil e validade.
- Se o e-mail ainda não existe, o usuário cria a senha.
- Se já existe, o convite adiciona uma associação após autenticação.
- Convites são de uso único.
- Tokens de convite são armazenados apenas como hash.

---

## 16. Autenticação híbrida

### 16.1 Access token

- Formato JWT.
- Duração inicial sugerida: 10 minutos.
- Assinatura assimétrica, como Ed25519 ou RSA.
- `servicelog-api` recebe somente chave pública.
- Validar emissor, audiência, assinatura, emissão e expiração.

Claims mínimas:

```json
{
  "sub": "user_uuid",
  "sid": "session_uuid",
  "org": "organization_uuid",
  "aud": "servicelog-api",
  "permission_version": 12,
  "iat": 1788432000,
  "exp": 1788432600
}
```

Não incluir toda a matriz de permissões no JWT.

### 16.2 Refresh token

- Token opaco e aleatório.
- Duração inicial sugerida: 30 dias.
- Limite absoluto de sessão sugerido: 90 dias.
- Armazenar somente hash no PostgreSQL.
- Associar a sessão, usuário e dispositivo.
- Rotacionar a cada utilização.
- Detectar reutilização de token antigo.
- Revogar a família da sessão quando houver reutilização suspeita.

### 16.3 Sessões

```text
iam.sessions
- id
- user_id
- device_id
- created_at
- last_seen_at
- expires_at
- revoked_at
- revoke_reason
- ip_metadata
- user_agent_metadata
```

```text
iam.refresh_tokens
- id
- session_id
- token_hash
- family_id
- parent_id
- created_at
- expires_at
- used_at
- revoked_at
```

### 16.4 Revogação

Permitir:

- logout atual;
- revogar dispositivo;
- revogar todas as sessões;
- bloquear usuário;
- remover associação da organização;
- incrementar `token_version` ou `permission_version`.

PostgreSQL é a fonte oficial. Valkey acelera a consulta de sessões revogadas e versões.

---

## 17. Autorização e permissões por campo

### 17.1 Modelo

```text
Organização
↓
Perfil
↓
Permissões do perfil
↓
Exceções do usuário
```

Tabelas conceituais:

```text
app.roles
app.permission_catalog
app.role_permissions
app.user_permission_overrides
```

### 17.2 Chaves

```text
client.read
client.create
client.update
client.delete

client.name.read
client.name.write
client.phone.read
client.phone.write
client.internal_notes.read
client.internal_notes.write

equipment.serial.read
equipment.serial.write
equipment.cost.read
equipment.cost.write
```

### 17.3 Precedência

```text
Negação explícita do usuário
↓
Permissão explícita do usuário
↓
Permissão concedida pelo perfil
↓
Negação padrão
```

### 17.4 Backend obrigatório

O backend deverá:

- verificar ação e recurso;
- remover ou mascarar campos sem permissão de leitura;
- rejeitar escrita de campos não autorizados;
- nunca confiar apenas na ocultação da interface;
- auditar operações sensíveis;
- negar novos campos até serem registrados no catálogo.

O cliente Flutter ocultará ou desabilitará controles para melhorar a experiência, mas não será autoridade de segurança.

### 17.5 Administração

Embora o motor suporte granularidade por campo, a interface apresentará grupos por padrão:

- dados básicos;
- contatos;
- dados fiscais;
- informações técnicas;
- custos e valores;
- notas internas;
- fotos e documentos.

Uma seção avançada permitirá exceções por campo.

### 17.6 Cache

O conjunto de permissões calculado poderá ser armazenado no Valkey:

```text
org:{organization_id}:permissions:{user_id}:v{permission_version}
```

Alterações de perfil ou usuário incrementam a versão e invalidam o cache.

---

## 18. Banco local e segurança offline

### 18.1 Tecnologia

Usar SQLite com Drift no Flutter.

O banco local deverá ser criptografado. A chave fica no Keychain/Keystore ou mecanismo seguro equivalente do sistema operacional.

### 18.2 Separação local

Manter banco por organização:

```text
servicelog-{organization_id}.sqlite
```

Mesmo que o MVP permita somente uma organização por usuário, essa separação reduz riscos futuros.

### 18.3 Sessão offline

O primeiro login no dispositivo exige internet.

Depois:

```text
Sessão previamente validada
↓
Sem conexão
↓
PIN ou biometria
↓
Validar prazo offline
↓
Acessar dados locais autorizados
```

Prazo inicial sugerido: 7 dias desde a última validação online, configurável por organização no futuro.

Não é possível revogar imediatamente um aparelho totalmente desconectado. Ao reconectar:

- validar sessão antes da sincronização;
- revalidar associação e permissões;
- rejeitar operações não autorizadas;
- não apagar silenciosamente alterações locais rejeitadas.

---

## 19. Sincronização

### 19.1 Identificadores

Entidades criadas offline usam UUIDs gerados pelo cliente. Não depender de sequences do servidor.

### 19.2 Metadados

No servidor:

```text
id
organization_id
version
created_at
updated_at
deleted_at
created_by
updated_by
```

No cliente:

```text
sync_status
server_version
local_updated_at
last_synced_at
sync_error
```

### 19.3 Outbox

Cada alteração local e seu evento de sincronização devem ser gravados na mesma transação SQLite.

```text
sync_outbox
- operation_id UUID
- organization_id
- entity_type
- entity_id
- operation_type
- payload
- base_version
- occurred_at
- attempts
- last_error
```

### 19.4 Protocolo

Fluxo conceitual:

```text
POST /v1/sync/push
↓
Enviar operações pendentes
↓
Validar sessão, tenant e permissões
↓
Aplicar com idempotência
↓
Retornar accepted/rejected/conflict
↓
GET /v1/sync/pull?cursor=...
↓
Baixar mudanças posteriores ao cursor
```

Cada operação usa `operation_id` como chave de idempotência.

### 19.5 Concorrência

Usar controle otimista com `version`/`base_version` para registros editáveis.

Não adotar uma política universal de `last write wins`. Conflitos devem ter política por domínio. Para QR Code, vale exclusivamente a regra da primeira associação confirmada.

### 19.6 Exclusão

Usar tombstones (`deleted_at`) durante uma janela de retenção. Exclusão física imediata pode fazer outro dispositivo recriar registros antigos.

### 19.7 Fotos e arquivos

- Salvar arquivo localmente até o upload.
- Criar item na fila de upload.
- Usar hash para integridade e deduplicação técnica.
- Suportar retomada de upload quando necessário.
- Sincronizar metadados separadamente do conteúdo binário.
- Não marcar a ordem como completamente sincronizada enquanto anexos obrigatórios estiverem pendentes.

---

## 20. Valkey

Valkey será usado como cache open source com licença permissiva BSD-3-Clause.

Usos autorizados:

- cache de permissões;
- sessões revogadas;
- rate limiting;
- códigos temporários;
- locks de curta duração;
- idempotência temporária;
- cache de consultas;
- coordenação de jobs não críticos.

Não usar como fonte oficial de:

- usuários;
- refresh tokens;
- permissões;
- organizações;
- ordens;
- associações de QR Code;
- fila definitiva de sincronização;
- auditoria.

Se Valkey ficar indisponível, o sistema poderá perder desempenho, mas não integridade de dados.

Chaves multitenant:

```text
org:{organization_id}:permissions:{user_id}
org:{organization_id}:equipment:{equipment_id}
session:revoked:{session_id}
rate:login:{normalized_email}:{ip_hash}
```

Nunca criar chaves de negócio sem o contexto da organização.

---

## 21. Modelo de dados inicial

### IAM

```text
iam.users
iam.devices
iam.sessions
iam.refresh_tokens
iam.password_reset_tokens
iam.invitations
```

### Organizações e permissões

```text
app.organizations
app.organization_memberships
app.roles
app.permission_catalog
app.role_permissions
app.user_permission_overrides
```

### Dados operacionais

```text
app.clients
app.client_contacts
app.locations
app.equipment_types
app.equipments
app.service_order_types
app.service_orders
app.service_order_parts
app.service_order_photos
app.service_order_signatures
app.documents
app.recommendations
```

### Etiquetas

```text
app.qr_codes
app.qr_batches
app.qr_batch_issues
app.qr_assignments
app.qr_assignment_attempts
app.label_templates
app.label_exports
app.label_export_items
```

### Infraestrutura funcional

```text
app.sync_operations
app.sync_cursors
app.outbox_events
audit.audit_events
```

### `qr_codes`

Campos mínimos:

```text
id UUID
organization_id UUID
public_code
status
batch_id NULL
reserved_user_id NULL
reserved_device_id NULL
assigned_entity_type NULL
assigned_entity_id NULL
assigned_at NULL
assigned_by NULL
created_at
updated_at
```

O vínculo polimórfico precisa ser validado na camada de serviço e protegido por constraints/índices adequados. Como alternativa mais rigorosa, criar tabelas de vínculo específicas por tipo. Registrar a decisão em ADR.

### `qr_assignment_attempts`

```text
id
organization_id
qr_code_id
entity_type
entity_id
operation_id
attempted_by
attempted_device_id
attempted_at_client
received_at_server
result
reason
```

Essa tabela preserva conflitos e tentativas sem alterar o vínculo válido.

### Índices importantes

- `organization_id` em todas as tabelas tenant-scoped.
- busca por nome de cliente dentro da organização;
- busca por serial do equipamento dentro da organização;
- código público da etiqueta;
- ordens por equipamento e data;
- registros alterados por cursor de sincronização;
- operações por `operation_id`.

---

## 22. API

### 22.1 Convenções

- Prefixo `/v1`.
- JSON.
- Datas em ISO 8601 e UTC.
- IDs UUID serializados como string.
- Paginação por cursor.
- `Idempotency-Key` em operações criáveis/repetíveis.
- Erros com código estável e mensagem localizada no cliente.
- Não aceitar `organization_id` de negócio para substituir o tenant do token.

Envelope de erro sugerido:

```json
{
  "error": {
    "code": "QR_CODE_ALREADY_ASSIGNED",
    "message": "The label is already assigned.",
    "details": {},
    "request_id": "uuid"
  }
}
```

### 22.2 Auth

```text
POST   /v1/auth/login
POST   /v1/auth/refresh
POST   /v1/auth/logout
POST   /v1/auth/logout-all
POST   /v1/auth/password/forgot
POST   /v1/auth/password/reset
GET    /v1/auth/sessions
DELETE /v1/auth/sessions/{id}
```

### 22.3 Organizações e usuários

```text
GET    /v1/me
GET    /v1/organization
PATCH  /v1/organization
GET    /v1/users
POST   /v1/users/invitations
PATCH  /v1/users/{id}
DELETE /v1/users/{id}/membership
GET    /v1/roles
POST   /v1/roles
PATCH  /v1/roles/{id}
PUT    /v1/users/{id}/permission-overrides
```

### 22.4 Clientes, locais e equipamentos

```text
GET/POST       /v1/clients
GET/PATCH      /v1/clients/{id}
GET/POST       /v1/clients/{id}/locations
GET/PATCH      /v1/locations/{id}
GET/POST       /v1/locations/{id}/equipments
GET/PATCH      /v1/equipments/{id}
GET            /v1/equipments/{id}/history
```

### 22.5 Ordens

```text
GET/POST       /v1/service-orders
GET/PATCH      /v1/service-orders/{id}
POST           /v1/service-orders/{id}/start
POST           /v1/service-orders/{id}/complete
POST           /v1/service-orders/{id}/parts
POST           /v1/service-orders/{id}/photos
POST           /v1/service-orders/{id}/signature
POST           /v1/service-orders/{id}/pdf
```

### 22.6 Etiquetas

```text
POST           /v1/qr-codes
GET            /v1/qr-codes/resolve/{public_code}
POST           /v1/qr-codes/{id}/assign
POST           /v1/qr-codes/{id}/replace
POST           /v1/qr-codes/{id}/deactivate
GET/POST       /v1/qr-batches
POST           /v1/qr-batches/{id}/reserve
POST           /v1/qr-batches/{id}/export
POST           /v1/qr-batches/{id}/mark-lost
```

### 22.7 Sincronização

```text
POST           /v1/sync/push
GET            /v1/sync/pull?cursor={cursor}
GET            /v1/sync/bootstrap
```

A especificação OpenAPI deve ser versionada no repositório e usada para gerar ou validar clientes quando conveniente.

---

## 23. Auditoria

Registrar pelo menos:

- login, logout e falha de login;
- criação/revogação de sessão;
- convite e alteração de usuário;
- mudança de perfil ou permissão;
- criação e alteração de cliente/local/equipamento;
- finalização/reabertura de ordem;
- emissão e reimpressão de lote;
- atribuição, rejeição, substituição e desativação de etiqueta;
- resolução de pendência de conflito;
- exportação de PDF e dados.

Evento:

```text
audit.audit_events
- id
- organization_id
- actor_user_id
- actor_device_id
- action
- resource_type
- resource_id
- metadata JSONB
- request_id
- occurred_at
```

Não registrar senhas, refresh tokens, chaves ou conteúdo sensível completo. Para alterações de campos sensíveis, armazenar metadados ou valores mascarados conforme a política de segurança.

Auditoria deve ser append-only para a aplicação normal.

---

## 24. Segurança

Requisitos mínimos:

- Hash de senha com Argon2id e parâmetros versionados.
- Normalização consistente de e-mail.
- Rate limiting no login e recuperação.
- Tokens aleatórios gerados com CSPRNG.
- Refresh tokens armazenados somente como hash.
- Chaves privadas fora do repositório.
- Rotação de chaves com identificador `kid`.
- TLS em todas as conexões externas.
- Credenciais de banco distintas por serviço.
- RLS em tabelas tenant-scoped.
- Validação de autorização no backend.
- URLs assinadas e temporárias para arquivos privados.
- Criptografia do banco local.
- Segredos em armazenamento seguro do dispositivo.
- Bloqueio do aplicativo por PIN/biometria.
- Logs sem dados sensíveis.
- Backup e teste periódico de restauração.

O conhecimento de um código de etiqueta nunca concede acesso. Usuário não autenticado recebe apenas autenticação, sem confirmação de que aquele cliente ou equipamento existe.

---

## 25. Requisitos não funcionais

### Confiabilidade

- Requisições repetidas de sincronização não podem duplicar dados.
- Queda de Valkey não pode causar perda de dados.
- Falha de upload não pode apagar a foto local.
- Conflito de QR não pode apagar nem alterar dados operacionais.
- Migrações devem ser transacionais quando possível e reversíveis por nova migration.

### Desempenho inicial

- Abrir um equipamento já sincronizado localmente sem depender da rede.
- Busca local por cliente/equipamento em tempo percebido como imediato.
- Endpoints comuns com paginação e índices adequados.
- PDFs e tarefas pesadas processados em background.

### Observabilidade

- logs estruturados;
- `request_id` e `operation_id`;
- métricas de latência, erro, fila e sincronização;
- health checks separados para processo e dependências;
- rastreamento de falhas de tenant e autorização sem expor dados.

### Internacionalização

- Interface preparada para português, italiano, inglês e espanhol.
- Textos de erro estáveis no backend e traduzidos no cliente.
- Datas, números, telefones e documentos apresentados conforme locale.
- Armazenamento de timestamps em UTC.

---

## 26. Estratégia de testes

### 26.1 Isolamento multitenant

Testes obrigatórios:

- usuário da organização A não lista dados da B;
- busca direta por UUID da B retorna não encontrado/negado;
- tentativa de relacionar cliente A com local B falha;
- RLS bloqueia consulta sem contexto de organização;
- worker não processa evento com tenant incorreto;
- cache nunca entrega dados de outro tenant.

### 26.2 Permissões

- campo sem `read` não é retornado;
- campo sem `write` é rejeitado;
- UI oculta campo proibido;
- negação do usuário prevalece sobre o perfil;
- permissão explícita válida funciona;
- campo novo inicia negado;
- alteração de permissão invalida cache e versão.

### 26.3 Autenticação

- refresh rotaciona;
- refresh antigo reutilizado revoga a família;
- logout revoga sessão;
- troca de senha pode revogar sessões;
- token de outra audiência é recusado;
- token expirado é recusado;
- usuário desativado não sincroniza.

### 26.4 Offline e sincronização

- criação offline sincroniza uma vez;
- repetição de `operation_id` não duplica;
- tombstone chega aos demais dispositivos;
- upload interrompido é retomado;
- operação feita com permissão posteriormente revogada é rejeitada sem apagar o dado local;
- bootstrap cria uma base local consistente.

### 26.5 Etiquetas

- leitura e digitação resolvem o mesmo código;
- código com erro de verificação é rejeitado;
- etiqueta livre pode ser vinculada;
- etiqueta reservada por outro técnico não pode ser confirmada offline;
- primeira associação confirmada permanece válida;
- segunda associação é recusada;
- segundo registro é preservado;
- segunda associação cria pendência de substituição;
- nenhuma mesclagem ou transferência acontece;
- substituição posterior resolve a pendência;
- lote perdido não aceita associação;
- reimpressão gera auditoria.

---

## 27. Critérios de aceite principais

### Cadastro

- Usuário autorizado cadastra cliente, local e equipamento online ou offline.
- Falha ao adicionar etiqueta não desfaz o cadastro.
- Usuário sem permissão de campo não visualiza nem altera o campo.

### Etiqueta existente

- Usuário escolhe escanear ou digitar.
- Sistema mostra o destino antes da confirmação.
- Código válido e disponível é associado.
- Código já associado é recusado.

### Nova etiqueta

- Sistema cria o código e vincula ao registro.
- Usuário pode imprimir imediatamente ou depois.
- Código pode ser digitado quando o QR estiver ilegível.

### Offline

- Aplicativo abre dados locais para sessão offline válida.
- Técnico usa etiquetas previamente reservadas.
- Operações ficam visivelmente pendentes.
- Sincronização posterior confirma ou rejeita cada operação.

### Conflito

- Primeira associação confirmada não muda.
- Registro posterior não perde nenhum dado.
- Registro posterior recebe `REPLACEMENT_REQUIRED`.
- Usuário pode substituir agora ou posteriormente.
- Auditoria registra toda a sequência.

### Multitenancy

- Não existe caminho conhecido pela API ou banco da aplicação para acessar dados de outra organização com uma sessão comum.

---

## 28. Plano de implementação

### Fase 0 — Fundação

- monorepo;
- Docker Compose;
- configuração por ambiente;
- migrations;
- logging estruturado;
- IDs e relógio abstratos para testes;
- tratamento de erros;
- CI inicial;
- OpenAPI inicial.

### Fase 1 — IAM e multitenancy

- organizações;
- usuários globais;
- associações;
- convites;
- autenticação híbrida;
- sessões e revogações;
- RLS;
- perfis e permissões;
- testes de isolamento.

### Fase 2 — Aplicativo Flutter básico

- estrutura modular;
- login;
- armazenamento seguro;
- SQLite/Drift;
- banco por organização;
- navegação principal;
- renderização baseada em permissões;
- sessão offline.

### Fase 3 — Cadastros principais

- clientes;
- locais;
- tipos de equipamento;
- equipamentos;
- busca e filtros;
- histórico básico;
- auditoria.

### Fase 4 — Etiquetas

- códigos públicos;
- leitura e digitação;
- criação e associação;
- lotes;
- reserva para técnico/dispositivo;
- modelos de impressão;
- texto personalizado;
- PDF de etiquetas;
- conflitos e substituição.

### Fase 5 — Ordens de serviço

- estados da ordem;
- diagnóstico;
- serviço realizado;
- peças;
- fotos;
- recomendações;
- assinatura;
- relatório PDF.

### Fase 6 — Sincronização completa

- outbox local;
- push/pull;
- cursor;
- idempotência;
- tombstones;
- uploads retomáveis;
- pendências;
- políticas de conflito por domínio.

Partes da sincronização devem ser prototipadas antes, especialmente IDs offline e criação local, mas esta fase consolida e endurece o mecanismo.

### Fase 7 — Hardening e piloto

- testes de carga básicos;
- revisão de segurança;
- backup/restauração;
- métricas e alertas;
- distribuição desktop/mobile;
- piloto com uma organização;
- piloto com múltiplas organizações;
- correções de usabilidade em campo.

---

## 29. Decisões que não devem ser revertidas sem aprovação

1. PostgreSQL é a fonte oficial.
2. O banco é compartilhado e isolado por `organization_id` e RLS.
3. O e-mail identifica um usuário global.
4. O login não solicita seleção de organização.
5. O Auth é separado do domínio, pelo menos logicamente.
6. O modelo híbrido usa JWT curto e refresh token opaco rotativo.
7. Permissões são aplicadas no backend e podem chegar ao nível de campo.
8. Flutter atende mobile e desktop inicialmente.
9. SQLite/Drift é a base local.
10. Valkey é cache, nunca fonte oficial.
11. QR e dig code realizam a mesma identificação.
12. Cliente, local e equipamento podem possuir etiqueta.
13. É possível usar etiqueta existente ou criar uma nova.
14. Cadastro é salvo antes da etapa opcional de etiqueta.
15. Etiquetas de lote podem ser reservadas para uso offline.
16. A primeira associação de etiqueta confirmada pelo servidor vence.
17. A associação posterior exige substituição da etiqueta.
18. Conflito de etiqueta nunca mescla, transfere ou exclui dados.

---

## 30. Decisões ainda abertas

Estas decisões podem ser tomadas durante o planejamento, com ADR:

- biblioteca HTTP/router Go;
- biblioteca de queries/migrations PostgreSQL;
- algoritmo exato e tamanho do código textual;
- Ed25519 ou RSA para JWT;
- implementação de criptografia SQLite compatível com as plataformas alvo;
- provedor/implementação S3-compatible;
- tamanhos físicos iniciais das etiquetas;
- formato de assinatura;
- serviço de e-mail;
- duração final dos tokens e da sessão offline;
- política de retenção de tombstones e auditoria;
- nicho inicial e campos específicos do tipo de equipamento;
- sistema de notificações.

Escolher soluções simples, maduras, testáveis e com licença compatível com produto comercial. Registrar versões e licenças das dependências.

---

## 31. Referências técnicas

- PostgreSQL Row-Level Security: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- OAuth 2.0 Security Best Current Practice: https://www.rfc-editor.org/info/rfc9700/
- Flutter Desktop: https://docs.flutter.dev/platform-integration/desktop
- Drift — plataformas: https://drift.simonbinder.eu/platforms/
- Valkey: https://github.com/valkey-io/valkey
- Licença Valkey: https://github.com/valkey-io/valkey/blob/unstable/LICENSES/BSD-3-Clause.txt
- Licenças Redis: https://redis.io/legal/licenses/

---

## 32. Prompt inicial sugerido para Claude Code

Copie o conteúdo abaixo junto com este documento:

```text
Você iniciará o desenvolvimento do ServiceLog usando esta especificação como
fonte de requisitos.

Antes de escrever código:

1. Leia integralmente servicelog-especificacao-funcional-tecnica.md.
2. Inspecione o repositório e quaisquer arquivos AGENTS.md ou CLAUDE.md.
3. Produza um plano apenas para as Fases 0 e 1.
4. Identifique decisões técnicas abertas que bloqueiam essas fases.
5. Não implemente módulos de negócio antes de concluir e testar autenticação,
   multitenancy, RLS e permissões.
6. Crie ADRs para decisões relevantes.
7. Não altere as regras definitivas de QR Code e conflito.

Após apresentar o plano, implemente a fundação de forma incremental, execute os
testes e documente como subir o ambiente local. PostgreSQL deve ser a fonte
oficial; Valkey deve ser apenas cache. Todo acesso tenant-scoped deve possuir
testes negativos entre organizações.
```

---

## 33. Resumo executivo para implementação

O ServiceLog será uma aplicação offline-first para registrar clientes, locais, equipamentos e serviços. Cada organização prestadora compartilha a mesma infraestrutura PostgreSQL, mas seus dados são isolados por `organization_id`, aplicação e RLS.

Usuários possuem identidade global por e-mail e entram diretamente na organização padrão, sem seleção no login. O Auth utiliza access token JWT curto e refresh token opaco, rotativo e revogável. Permissões combinam perfis com exceções individuais e podem controlar leitura e escrita de campos.

Flutter atenderá mobile e desktop. SQLite/Drift armazenará dados locais, permissões offline, operações pendentes e metadados de sincronização. Mudanças serão enviadas por uma outbox idempotente e recebidas por cursor.

Cliente, local e equipamento podem receber etiquetas. O usuário pode escanear um QR Code, digitar o código impresso ou criar uma nova etiqueta. Lotes são gerados antecipadamente, emitidos, reservados e sincronizados para permitir atribuição offline segura.

Em conflito, a primeira associação confirmada pelo servidor permanece. A associação posterior é recusada, todos os dados do registro posterior são preservados e é criada uma pendência para substituição física da etiqueta. Não existe mesclagem automática de dados.

O desenvolvimento deve priorizar segurança multitenant, autorização e consistência offline antes da expansão funcional.
