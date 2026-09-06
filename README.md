# ServiceLog — app Flutter

App cliente do ServiceLog: iOS, Android e Web (Chrome). Consome o backend do
repositório irmão `auth_servory` (`~/go/src/auth_servory` localmente) —
`auth-api` (login/refresh/sessões) + `servicelog-api` (tudo mais).

Fonte de requisitos: [`servicelog-especificacao-funcional-tecnica.md`](servicelog-especificacao-funcional-tecnica.md).
Contrato consumido a partir do backend: [`docs/GUIA-FLUTTER.md`](docs/GUIA-FLUTTER.md).
Estado do projeto (backend e app): [`docs/progresso.md`](docs/progresso.md).

## Escopo até agora

- **Fundação**: estrutura, tema, roteamento (`go_router`), cliente HTTP com
  refresh automático de token (`dio`), armazenamento seguro de sessão
  (`flutter_secure_storage`), login, Home consumindo `/v1/me`.
- **Offline (só iOS/Android)**: banco local criptografado (Drift +
  SQLite3 Multiple Ciphers), sessão offline por biometria/PIN do aparelho
  (spec §18.3), sincronização (`bootstrap`/`pull`/`push`) de
  `client`/`location`/`equipment` — escrita local (create/update) só em
  `client` por ora.

O Chrome roda **sempre online**: chama a API diretamente a cada tela, sem
banco local nem sessão offline — todo o esforço de offline-first (spec §18,
§19) fica restrito a iOS/Android, que é quem vai a campo sem sinal.

### Criptografia do banco local

`sqlcipher_flutter_libs` está obsoleto (sqlite3 v3+ mudou para hooks de
build). Este projeto usa a alternativa recomendada pelo próprio mantenedor
do drift — configurado em `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc   # SQLite3 Multiple Ciphers
```

Isso faz o `sqlite3` bundlar um binário com suporte a `PRAGMA key`/`PRAGMA
cipher` automaticamente no primeiro `flutter pub get`/`flutter run` — nada
de instalar nada manualmente. A chave (256 bits, gerada uma vez por
organização) fica só no Keychain/Keystore via `flutter_secure_storage`
(`lib/core/db/db_key_store.dart`), nunca é enviada ao servidor.

### Codegen (Drift)

Depois de editar `lib/core/db/app_database.dart` (tabelas), regenere:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Pré-requisitos

- Flutter 3.47+ (`flutter --version`)
- O backend rodando localmente — ver `~/go/src/auth_servory/README.md`
  (`make up` sobe `auth-api` :8080 + `servicelog-api` :8081 + Postgres +
  Valkey + MinIO + Mailpit via Docker Compose)

## Rodar contra o backend local

Por padrão (sem `--dart-define`), o app já resolve os hosts certos por
plataforma — `localhost` no Chrome/iOS simulator, `10.0.2.2` no emulador
Android (`lib/core/config/app_config.dart`):

```bash
flutter run -d chrome
flutter run -d <ios-simulator-id>      # flutter devices para listar
flutter run -d <android-emulator-id>
```

Para apontar para outro ambiente (staging, dispositivo físico na mesma
rede, produção):

```bash
flutter run -d chrome \
  --dart-define=AUTH_BASE_URL=http://192.168.0.10:8080 \
  --dart-define=API_BASE_URL=http://192.168.0.10:8081
```

### Criar um usuário de teste

O backend não tem cadastro público — o primeiro admin de uma organização
nasce pelo CLI do `auth-api` (`~/go/src/auth_servory`):

```bash
cd ~/go/src/auth_servory
docker compose -f deploy/docker-compose.yml run --rm auth-api bootstrap \
  --org "Minha Empresa" --email admin@exemplo.com --name "Admin" --password "SenhaForte123"
```

### CORS (só relevante para o alvo Web)

`auth-api`/`servicelog-api` liberam CORS via `CORS_ALLOWED_ORIGINS` (default
`*` em dev — seguro aqui porque a autenticação é só via
`Authorization: Bearer`, sem cookie de sessão). Se você mudar essa variável
para uma lista restrita, inclua a origem que o `flutter run -d chrome`
efetivamente usa (a porta varia; veja a URL impressa no terminal ao rodar).

## Testes

```bash
flutter analyze
flutter test
```

## Estrutura

```
lib/
  core/            config, cliente HTTP + interceptor de refresh,
                   armazenamento seguro, banco local (Drift), roteamento,
                   conectividade, biometria, tema — genérico, sem regra de
                   nenhuma feature específica
  features/
    auth/          login, sessão, trava do app offline
    me/             /v1/me, /v1/me/permissions
    sync/           bootstrap/pull/push (client/location/equipment)
    clients/        lista + criar/editar (local -> outbox -> push)
    locations/      lista (só leitura)
    equipments/     lista (só leitura)
```

Cada feature nova segue o mesmo molde (`data/` chamadas HTTP tipadas,
`application/` providers Riverpod, `presentation/` widgets).

# Handoff: Leiano ServiceReport — marca e telas mobile

## Visão geral

Identidade visual do app **ServiceReport** (antes chamado ServiceLog / Servory) e o desenho de seis telas mobile em iOS e Android. O app é o de ordens de serviço em Flutter que vive em \`app_servory\`: clientes, locais, equipamentos, ordens, etiquetas e empresas, com operação offline.

O nome do produto na interface é **ServiceReport** — o título "ServiceLog" que está hoje em \`login_screen.dart\` e \`home_screen.dart\` deve ser substituído.

## Sobre os arquivos deste pacote

Os arquivos \`.dc.html\` são **referências de design feitas em HTML** — protótipos que mostram aparência e comportamento pretendidos, não código de produção para copiar. A tarefa é **recriar estes desenhos no ambiente do app**: Flutter + Material 3, com Riverpod e go_router, seguindo os padrões já estabelecidos em \`lib/features/*/presentation\`. Nada de HTML no app.

Abra os arquivos em qualquer navegador para ver as telas renderizadas.

## Fidelidade

**Alta fidelidade.** Cores, tipografia, espaçamentos e textos são finais. Reproduza fielmente, usando os widgets nativos de cada plataforma onde a barra/navegação é do sistema.

---

## Marca

### Ícone

Quatro faixas retas numa grade de 24 × 24, formando um S em zigue-zague. Coordenadas exatas (x, y, largura, altura):

| Faixa | x | y | largura | altura | cor |
|---|---|---|---|---|---|
| 1 | 4 | 2 | 14 | 4 | branco |
| 2 | 4 | 7,5 | 8 | 4 | azul |
| 3 | 10 | 13 | 8 | 4 | branco |
| 4 | 4 | 18,5 | 14 | 4 | azul |

Sempre sobre bloco quadrado \`#12151A\`, sem canto arredondado. Em fundo claro as faixas brancas viram \`#12151A\` e o azul vira \`#3A61C4\`.

**Abaixo de 20 px** (favicon, ícone monocromático, notificação): todas as quatro faixas em uma só cor, sem o azul — o vão fecha e o desenho suja.

SVG de referência (24 × 24, fundo escuro):

\`\`\`svg
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
<rect x="4" y="2" width="14" height="4" fill="#FFFFFF"/>
<rect x="4" y="7.5" width="8" height="4" fill="#618DF3"/>
<rect x="10" y="13" width="8" height="4" fill="#FFFFFF"/>
<rect x="4" y="18.5" width="14" height="4" fill="#618DF3"/>
</svg>
\`\`\`

### Assinatura (lockup)

Bloco preto quadrado com o ícone + quadro contíguo com o texto, sem espaço entre os dois:

- bloco: \`#12151A\`, largura 62 px na versão principal (ícone a 30 px dentro)
- quadro: borda 1 px \`#12151A\`, sem borda esquerda, padding 11 px 20 px
- linha 1: \`leiano\` — IBM Plex Mono, 11 px, letter-spacing 0,24em, \`#4C5057\`
- linha 2: \`servicereport\` — IBM Plex Mono 500, 26 px, letter-spacing −0,03em, \`#12151A\`

Nome do produto **sempre em caixa baixa, uma palavra, sem espaço nem hífen**.

Área livre mínima em todos os lados: metade da altura do bloco preto.

### Ícones de app e favicon

| Uso | Tamanho | Observação |
|---|---|---|
| iOS app icon | 1024 × 1024 | bloco \`#12151A\` sangrando, ícone ocupando 52% da largura, azul \`#618DF3\` |
| Android adaptive | 432 × 432 (foreground 264) | mesma proporção, sem canto arredondado no foreground |
| favicon web | 32 e 16 | 16 px monocromático branco sobre \`#12151A\` |
| notificação Android | 24 | silhueta branca das quatro faixas |

Substituir: \`web/favicon.png\`, \`web/icons/*\`, \`ios/Runner/Assets.xcassets/AppIcon.appiconset\`, \`android/app/src/main/res/mipmap-*\`.

---

## Design tokens

### Cores

| Token | Hex | Uso |
|---|---|---|
| Tinta | \`#12151A\` | app bar, texto, botão primário, bloco da marca, fundos escuros |
| Azul | \`#3A61C4\` | acento sobre fundo claro, links, contadores, ícone de sync |
| Azul claro | \`#618DF3\` | acento sobre a tinta — nunca sobre branco |
| Fundo | \`#EDEEF0\` | fundo de tela |
| Superfície | \`#FFFFFF\` | cartões, listas, campos |
| Borda | \`#DCDEE2\` | borda de cartão e de campo em repouso |
| Divisor | \`#F0F1F3\` | separador entre itens de lista |
| Texto secundário | \`#4C5057\` | corpo secundário |
| Texto terciário | \`#71757C\` | rótulos, metadados |
| Texto desabilitado | \`#8A8F98\` | vazio, placeholder |
| Erro | \`#A3372A\` (barra), \`#7C2A20\` (texto), \`#FBEDEA\` (fundo) | mensagens de erro e conflito |
| Sobre escuro | \`#B4B9C1\` (secundário), \`#262A31\` (trilha), \`#4C5259\` (borda) | conteúdo sobre a tinta |

Máximo de duas cores por aplicação: tinta + um dos azuis. Sem gradiente, sem sombra na marca.

### Tipografia

Duas famílias, ambas no Google Fonts:

- **IBM Plex Mono** (400/500) — marca, números, rótulos, dados, códigos, datas, horas
- **Space Grotesk** (400/500/600) — títulos, corpo, botões

| Papel | Família | Tamanho | Peso | Letter-spacing |
|---|---|---|---|---|
| Título de tela (iOS) | Space Grotesk | 21 | 500 | −0,015em |
| Título de app bar (Android) | Space Grotesk | 17 | 500 | 0 |
| Nome em item de lista | Space Grotesk | 14 | 500 | 0 |
| Subtítulo de item | IBM Plex Mono | 11 | 400 | 0 |
| Corpo | Space Grotesk | 13–13,5 | 400 | 0 · line-height 1,5 |
| Rótulo de campo | IBM Plex Mono | 9,5 | 400 | 0,1–0,14em · caixa alta |
| Valor de campo | IBM Plex Mono | 13,5 | 400 | 0 |
| Botão | Space Grotesk | 14–15 | 500 | 0 |
| Número grande | IBM Plex Mono | 34–44 | 500 | −0,04em |
| Chip / badge | IBM Plex Mono | 10 | 400 | 0,1em · caixa alta |

Mínimo de 12 px em qualquer texto de interface.

### Forma e espaçamento

- **Raio de borda: 0 em tudo.** Cartões, campos, botões, chips, avatares, FAB — todos retos. É a decisão de forma mais importante do sistema.
- Borda: 1 px. Campo em foco/preenchido: \`#12151A\`. Em repouso: \`#DCDEE2\`.
- Espaçamento: 4 / 8 / 12 / 14 / 16 / 20 / 26 / 32.
- Padding de tela: 14 px nas listas, 16 px nos formulários, 20–24 px no login.
- Alvo de toque mínimo: 44 px (botões com padding 14–16 px verticais).
- Faixa colorida de 4 px à esquerda marca prioridade/estado em cartões; barra de 3 px à esquerda marca mensagem de erro.

---

## Telas

Arquivo: \`Servory Telas.dc.html\` (seis telas, iOS e Android lado a lado).

### 01 · Splash — rota \`/splash\`

Fundo \`#12151A\` inteiro. Marca centralizada: ícone a 80 px, \`leiano\` (IBM Plex Mono 9,5 px, letter-spacing 0,3em, \`#8A8F98\`) acima de \`servicereport\` (IBM Plex Mono 500, 21 px). Rodapé: "preparando dados do dispositivo" (IBM Plex Mono 10,5 px, \`#B4B9C1\`) e a versão (9,5 px, \`#71757C\`).

**Animação:** as quatro faixas do ícone pulsam em sequência — opacidade 0,22 → 1 → 0,22, ciclo de 1,6 s, ease-in-out, atrasos de 0 / 0,2 / 0,4 / 0,6 s. Em Flutter: \`AnimationController\` de 1600 ms em repeat, com quatro \`Interval\` deslocados alimentando o \`opacity\` de cada faixa.

**Android:** ganha uma barra de progresso linear M3 de 3 px acima do texto (trilha \`#262A31\`, indicador \`#618DF3\`). **iOS:** sem barra, só o pulso do ícone. Barra de status em modo claro (glifos brancos) nas duas.

### 02 · Login — rota \`/login\`

Fundo \`#EDEEF0\`, conteúdo centralizado, largura máxima 400 px.

De cima para baixo: bloco preto 54 × 54 com o ícone a 26 px; \`servicereport\` (IBM Plex Mono 500, 19 px); "Histórico de manutenção dos seus equipamentos" (13 px, \`#4C5057\`, centralizado); campo E-mail; campo Senha com botão de olho (46 px de largura); mensagem de erro quando houver; botão Entrar (padding 16 px, fundo \`#12151A\`, texto branco 15 px); rodapé "sessão offline válida por 7 dias" (IBM Plex Mono 9,5 px, \`#8A8F98\`).

**Estados:** campo preenchido tem borda \`#12151A\`; vazio, \`#DCDEE2\`. Erro da API aparece em caixa \`#FBEDEA\` com barra esquerda de 3 px \`#A3372A\` e texto \`#7C2A20\` — usar \`ApiException.friendlyMessage\`. Durante o envio o botão desabilita e mostra indicador de 20 px.

**Validação** (já no código): e-mail vazio → "Informe o e-mail."; sem @ → "E-mail inválido."; senha vazia → "Informe a senha."

**Diferença de plataforma:** iOS usa rótulo acima do campo; Android usa rótulo flutuante M3 recortando a borda (fundo do rótulo igual ao fundo da tela).

### 03 · Início e menu — rota \`/\`

App bar preta com a assinatura curta (ícone 18 px + \`servicereport\` 15 px) e ação de sair à direita.

Cartão de identidade: nome (16 px, 600), e-mail (IBM Plex Mono 11,5 px, \`#71757C\`), divisor, grade rótulo/valor com Organização e Perfil. Quando \`syncState.isLoading\`, linha com quadrado azul de 8 px + "sincronizando…" (IBM Plex Mono 11 px). Quando \`hasError\`, a mensagem de erro do código em \`#7C2A20\`.

Banner de conflito de etiqueta (só quando \`qrConflictCount > 0\`): fundo \`#FBEDEA\`, barra esquerda \`#A3372A\`, título "N etiquetas precisam ser substituídas" e a explicação do código.

Lista de atalhos, nesta ordem: **Ordens de serviço** (com contador azul), Clientes, Locais, Equipamentos, Etiquetas, Empresas. Item: 14 px peso 500, chevron \`#B4B9C1\`, separador \`#F0F1F3\`, altura mínima 48 px.

**Diferença:** iOS empilha os itens num cartão único com separadores internos; Android usa itens com 1 px de vão \`#DCDEE2\` entre eles (grade M3) e o ícone de logout na app bar.

### 04 · Ordens de serviço — rota \`/service-orders\`

Cabeçalho preto: contagem ("14 ordens", IBM Plex Mono 9 px, letter-spacing 0,16em) + título "Ordens de serviço" (21 px). Ação de tipos de ordem à direita → \`/type-catalog?kind=service-order\`.

Item de lista: nome do cliente (14 px, 500) + linha de status (IBM Plex Mono 11 px, \`#71757C\`) no formato \`<status> · <motivo>\`. Rótulos de status: Rascunho, Aberta, Em andamento, Concluída.

**Ícone à direita conforme \`syncStatus\`:** \`pending\` → nuvem com seta, 17 px, \`#3A61C4\`; \`conflict\` → triângulo de alerta, 17 px, \`#A3372A\`; sincronizado → nada.

Vazio: "Nenhuma ordem ainda. Puxe pra baixo para sincronizar." Pull-to-refresh chama \`refresh()\` + \`drainPendingUploads\`.

**Diferença:** iOS usa FAB quadrado de 56 px com "+"; Android usa FAB estendido "+ Nova ordem" (padding 17 × 20 px). Ambos → \`/service-orders/new\`.

### 05 · Detalhe da ordem — rota \`/service-orders/:id\`

Cabeçalho preto: nome do cliente (20 px) + chip de status e o botão da transição disponível. Chip: fundo \`#618DF3\`, texto \`#12151A\`, IBM Plex Mono 10 px caixa alta. Botão de transição: contorno \`#4C5259\`, texto branco. Transições do código: Aberta → **Iniciar**, Em andamento → **Concluir**, Concluída → **Reabrir**.

Depois, nesta ordem:

1. **Grade de referência** — Local, Equipamento, Agendamento (formato \`dd/mm/aaaa hh:mm\`), Técnico. Rótulo em IBM Plex Mono 9,5 px caixa alta à esquerda, valor à direita. No app são dropdowns; Local depende do cliente e Equipamento depende do local (desabilitados enquanto o pai não é escolhido). Tipo de ordem e Empresa emitente entram na mesma grade.
2. **Relatório** — campos Motivo, Diagnóstico (3 linhas), Serviço realizado (3 linhas), Condição final (2 linhas), Observações (3 linhas). Vazio mostra "—" em \`#8A8F98\`. Botão **Salvar** preto.
3. **Peças e materiais** — cabeçalho com "+ adicionar" (IBM Plex Mono 11 px, \`#3A61C4\`); linhas com descrição à esquerda e quantidade + unidade em IBM Plex Mono à direita.
4. **Recomendações para a próxima visita** — mesma estrutura de lista.
5. **Fotos** — grade de 3 colunas, células quadradas, gap 8 px; última célula é o alvo de captura (borda tracejada \`#B9BEC7\` + "+"). Rodapé "N envios pendentes" em \`#3A61C4\` quando houver fila.
6. **Assinatura** — moldura tracejada de 74 px com "sem assinatura", ou a imagem; botão **Coletar assinatura** com contorno.
7. **Gerar PDF (cópia de campo)** — botão com contorno, largura total → \`/service-orders/:id/report\`.

Erro de salvamento aparece acima do botão, em \`#7C2A20\`, com a mensagem do código ("Não foi possível salvar. Os dados ficam pendentes e tentam de novo sozinhos.").

**Diferença:** rótulo acima (iOS) contra rótulo flutuante (Android); voltar no topo à esquerda em ambos, com seta do sistema.

### 06 · Assinatura do cliente

Tela cheia. Cabeçalho preto com cancelar/fechar, título "Assinatura do cliente" e ação de limpar. Instrução "Peça para o cliente assinar abaixo." (13,5 px, \`#4C5057\`). Canvas branco ocupando o resto, borda 1 px \`#DCDEE2\`, com uma linha guia \`#E3E5E8\` a 120 px do fundo. Traço: 3,4 px, \`#12151A\`, ponta arredondada (bate com \`penStrokeWidth: 3\` do \`SignatureController\`). Botão **Salvar assinatura** preto, largura total; desabilitado enquanto o canvas está vazio e durante o envio. Rodapé "envio enfileirado — funciona offline".

Exporta PNG com fundo branco — único formato aceito pelo servidor.

**Diferença:** iOS põe cancelar e limpar como texto nas pontas do cabeçalho; Android usa ícones (X e lixeira) na app bar.

---

## Interações e comportamento

- **Navegação:** go_router, rotas como estão em \`app_router.dart\`. Nada de rota nova.
- **Pull-to-refresh** nas listas e no detalhe: \`repository.refresh()\` seguido de \`drainPendingUploads(ref)\`.
- **Carregando:** iOS mostra indicador circular; Android, barra linear no topo do conteúdo. Botões em envio ficam desabilitados com indicador de 20 px dentro.
- **Offline:** ícone de nuvem nos itens pendentes; a fila de anexos envia sozinha ao voltar a conexão. Sessão offline expira em 7 dias → \`/offline-expired\`.
- **Trava do app:** sem conexão e com sessão válida mas app travado → \`/unlock\` (biometria).
- **Transições de estado da ordem** passam \`baseVersion\` e podem devolver conflito — mostrar a mensagem da API, não um texto genérico.
- **Sem animação decorativa** além do pulso do splash e das transições nativas de navegação.

## Estado

Nada de novo: \`sessionControllerProvider\`, \`identityProvider\`, \`syncRunnerProvider\`, \`serviceOrderListProvider\`, \`serviceOrderByIdProvider\`, \`qrConflictCountProvider\`, \`referenceListProvider\`, \`attachmentControllerProvider\`. O desenho não pede campo novo no modelo.

## Assets

- Ícone da marca: SVG acima, quatro retângulos. Sem bitmap, sem imagem externa.
- Fontes: IBM Plex Mono e Space Grotesk (Google Fonts, SIL Open Font License). Empacotar em \`pubspec.yaml\` — não depender de rede.
- Ícones de interface: os do sistema (Material no Android, SF Symbols/Cupertino no iOS). Os SVGs nos protótipos são só indicação de forma.
- Fotos e assinaturas nas telas são placeholders.

## O que ainda não foi desenhado

Relatório/PDF em tela cheia (\`/service-orders/:id/report\`), captura de foto em tela cheia, listas e detalhes de clientes, locais, equipamentos, empresas e etiquetas, catálogo de tipos, unlock e offline-expired. Não existe apontamento de horas no app — a ordem registra peças, recomendações, fotos e assinatura.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| \`Servory Telas.dc.html\` | as seis telas, iOS e Android lado a lado |
| \`Logo primeiro App.dc.html\` | marca ServiceReport: horizontal, empilhada, negativa, monocromática, ícone de app |
| \`Logo Empresarial.dc.html\` | marca institucional Leiano Sistemas + manual (grade, área livre, paleta, usos incorretos) |
| \`ios-frame.jsx\` / \`android-frame.jsx\` | molduras de dispositivo usadas nos protótipos — referência, não implementar |
| \`support.js\` | runtime dos protótipos — ignorar |

Os \`.dc.html\` abrem direto no navegador.
