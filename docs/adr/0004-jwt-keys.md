# ADR-0004 — Chaves e formato do access token

- **Status:** aceito
- **Data:** 2026-09-03
- **Contexto da spec:** §16.1, §24

## Contexto

O access token é um JWT curto (10 min) com assinatura assimétrica: o `auth-api`
assina com a chave privada; o `servicelog-api` valida só com a pública (§16.1).
A spec exige rotação de chaves com identificador `kid` (§24).

## Decisão

- Algoritmo: **EdDSA / Ed25519**.
- Material de chave em arquivos PEM num diretório (`TOKEN_KEY_DIR`), fora do
  repositório e do controle de versão:
  - `<kid>.pem` — privada (PKCS#8), permissão `0600`.
  - `<kid>.pub.pem` — pública (PKIX).
- `TOKEN_ACTIVE_KID` seleciona a chave que assina novos tokens. Todas as chaves
  presentes no diretório continuam válidas para **verificação**, permitindo
  rotação sem downtime:
  1. gerar `<novo-kid>` e distribuir a pública ao servicelog-api;
  2. apontar `TOKEN_ACTIVE_KID` para o novo kid e reiniciar o auth-api;
  3. após ~10 min (expiração dos tokens antigos), remover a chave antiga.
- Claims: `iss`, `aud`, `sub` (user), `sid` (session), `org`, `permission_version`,
  `iat`, `exp`. A matriz de permissões **não** entra no token.
- Validação no consumidor: assinatura, `iss`, `aud`, `exp`, `iat`, e `kid`
  presente no conjunto de chaves públicas conhecidas.

## Alternativas consideradas

- **RSA (RS256):** tokens ~4x maiores no header de toda requisição; mais
  parâmetros de configuração (tamanho de chave, padding). Só valeria para um
  consumidor externo preso a RS256 — não é o caso.
- **HMAC (HS256):** simétrico; o servicelog-api passaria a poder emitir tokens.
  Viola §29 (item 5) e §16.1.
- **JWKS via HTTP:** útil com muitos consumidores; overkill para dois serviços
  na mesma VPS. Um diretório de PEMs versionado na configuração de deploy basta.

## Consequências

- `make keys` / `auth-api keygen <kid>` gera pares para dev (idempotente).
- O deploy da VPS injeta o diretório de chaves como secret montado.
- Comprometimento de chave: rotação é a mitigação; `token_version` e
  `permission_version` cobrem revogação lógica dentro da janela de 10 min.
