# ServiceLog — app Flutter

App cliente do ServiceLog: iOS, Android e Web (Chrome). Consome o backend do
repositório irmão `auth_servory` (`~/go/src/auth_servory` localmente) —
`auth-api` (login/refresh/sessões) + `servicelog-api` (tudo mais).

Fonte de requisitos: [`servicelog-especificacao-funcional-tecnica.md`](servicelog-especificacao-funcional-tecnica.md).
Contrato consumido a partir do backend: [`docs/GUIA-FLUTTER.md`](docs/GUIA-FLUTTER.md).
Estado do projeto (backend e app): [`docs/progresso.md`](docs/progresso.md).

## Escopo desta entrega (fundação)

Estrutura, tema, roteamento (`go_router`), cliente HTTP com refresh
automático de token (`dio`), armazenamento seguro de sessão
(`flutter_secure_storage`), tela de login e uma Home mínima consumindo
`/v1/me`. **Sem** banco local (SQLite/Drift), sessão offline por PIN/
biometria nem sincronização ainda — isso é escopo de uma entrega seguinte,
só para iOS/Android (ver decisão sobre o Chrome abaixo).

O Chrome roda **sempre online**: chama a API diretamente a cada tela, sem
banco local nem sessão offline — todo o esforço de offline-first (spec §18,
§19) fica restrito a iOS/Android, que é quem vai a campo sem sinal.

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
                   armazenamento seguro, roteamento, tema — genérico,
                   sem regra de nenhuma feature específica
  features/
    auth/          login, sessão (data/application/presentation)
    me/             /v1/me, /v1/me/permissions
```

Cada feature nova segue o mesmo molde (`data/` chamadas HTTP tipadas,
`application/` providers Riverpod, `presentation/` widgets).
