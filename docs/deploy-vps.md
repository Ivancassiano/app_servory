# Deploy em VPS única — passo a passo

Guia para colocar o ServiceLog no ar numa VPS única (uma máquina só, sem
Kubernetes/orquestrador — ver ADR-0002), usando Docker Compose. Pressupõe:

- uma VPS com Docker (e o plugin `docker compose`) já instalado;
- um domínio (ex.: `meudominio.com.br`) com o DNS **já apontando** (registro
  tipo A) para o IP dessa VPS.

Se alguma dessas duas coisas ainda não existe, resolva antes de continuar.

## 1. Entrar na VPS

No seu computador:

```bash
ssh usuario@IP_DA_VPS
```

## 2. Baixar o código

```bash
git clone <URL_DO_SEU_REPO_GITHUB> servicelog
cd servicelog
```

Se o repositório for **privado**, o `git clone` vai pedir usuário/senha — o
GitHub não aceita mais senha normal para isso, é preciso gerar um "Personal
Access Token" (GitHub → Settings → Developer settings → Personal access
tokens) e colar no lugar da senha.

## 3. Criar os arquivos de configuração (segredos)

Esses arquivos **nunca são commitados** (estão no `.gitignore`) — cada
ambiente (dev, essa VPS, uma futura segunda VPS) tem os seus.

```bash
cd deploy
cp prod.env.example prod.env
cp prod-business.env.example prod-business.env
cp prod-worker.env.example prod-worker.env
nano prod.env
```

`nano` é um editor de texto simples dentro do terminal (setas para navegar,
`Ctrl+O` salva, `Ctrl+X` sai). Dentro do `prod.env`, troque:

- `DOMAIN=` → o domínio de verdade (o que já aponta para essa VPS).
- `ACME_EMAIL=` → um e-mail seu (o Let's Encrypt avisa aí se o certificado
  tiver algum problema).
- Todo `CHANGE_ME_*` → uma senha forte e diferente para cada um. Pode gerar
  cada uma com:
  ```bash
  openssl rand -hex 16
  ```
- `POSTMARK_TOKEN` (e `MAIL_PROVIDER`/`MAIL_FROM_ADDRESS` se não for usar
  Postmark) → credencial do provedor de e-mail transacional.

Depois, abra os outros dois e troque só a senha — **precisa ser igual** à
que você colocou em `prod.env` para `SERVORY_BUSINESS_PASSWORD` e
`SERVORY_WORKER_PASSWORD` respectivamente (é o mesmo segredo repetido, cada
serviço lê o seu próprio arquivo):

```bash
nano prod-business.env
nano prod-worker.env
```

## 4. Gerar a chave de segurança (JWT)

Volte para a raiz do projeto e gere o par de chaves usado para assinar/
verificar os tokens de login (só precisa rodar uma vez; não precisa repetir
em cada atualização de código):

```bash
cd ..
docker compose -f deploy/docker-compose.prod.yml run --rm keygen
```

## 5. Subir tudo

```bash
docker compose -f deploy/docker-compose.prod.yml up -d --build
```

Isso builda as imagens e sobe banco de dados, cache, armazenamento de
arquivo, as duas APIs, o worker e o Caddy (proxy que cuida do HTTPS) — pode
demorar alguns minutos na primeira vez.

Para acompanhar se está subindo certo:

```bash
docker compose -f deploy/docker-compose.prod.yml logs -f
```

(`Ctrl+C` só sai do modo "acompanhar", não derruba nada.)

## 6. Testar

No navegador: `https://seudominio.com/healthz` — se aparecer algo como
`{"status":"ok",...}`, está no ar com certificado HTTPS válido (o Caddy pega
o certificado sozinho na primeira visita, via Let's Encrypt).

## 7. Criar o primeiro usuário admin

```bash
docker compose -f deploy/docker-compose.prod.yml exec auth-api /app bootstrap \
  -org "Sua Empresa" -email "voce@email.com" -name "Seu Nome" -password "uma-senha-forte"
```

## 8. Firewall

Libere só o necessário na VPS:

```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP (redireciona para HTTPS)
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

Banco de dados, cache e armazenamento de arquivo já ficam inacessíveis de
fora por padrão — o `docker-compose.prod.yml` só os expõe dentro da rede
interna dos containers.

## Para atualizar o código depois

```bash
cd servicelog
git pull
docker compose -f deploy/docker-compose.prod.yml up -d --build
```

Isso rebuilda só o que mudou e reinicia os serviços, sem precisar repetir os
passos 3–4 (configuração e chaves continuam as mesmas).

## Referência rápida

| Arquivo | O que é |
|---|---|
| `deploy/docker-compose.prod.yml` | Definição de todos os serviços (banco, cache, APIs, worker, Caddy) |
| `deploy/prod.env` | Segredos e config compartilhados (senhas de banco, domínio, e-mail, S3) |
| `deploy/prod-business.env` | Só a senha de banco do `servicelog-api` (papel de menor privilégio, ADR-0015) |
| `deploy/prod-worker.env` | Só a senha de banco do `worker` (papel de menor privilégio, ADR-0015) |
| `deploy/Caddyfile` | Roteamento HTTP + HTTPS automático |
