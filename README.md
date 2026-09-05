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
