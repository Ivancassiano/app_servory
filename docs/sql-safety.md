# Padrão de segurança contra SQL injection

Aplicado a partir do M0. Verificado no CI (`scripts/check-sql.sh`, alvo `make lint`)
e em toda revisão de código.

## Regras

1. **Valores sempre por bind parameter.** Em Go, todo valor vai como `$1, $2, …`
   nos métodos do `pgx` (`Exec`, `Query`, `QueryRow`) ou via código gerado pelo
   `sqlc`. O `pgx` usa o protocolo estendido do PostgreSQL: o texto da query e os
   parâmetros trafegam separados, nunca concatenados no cliente.

2. **Proibido montar SQL com `fmt.Sprintf`, `+`, `strings.Builder` ou templates
   a partir de valores.** Não existe query "simples o suficiente" para abrir
   exceção.

3. **Identificadores (tabela, coluna, schema, ordenação) nunca vêm de entrada do
   usuário.** Quando algo precisa ser dinâmico (ex.: coluna de `ORDER BY` vinda
   da API), o valor é resolvido contra um **allowlist** explícito no código e só
   o literal validado entra na query. Em `pgx`, use `pgx.Identifier{...}.Sanitize()`
   se realmente não houver alternativa.

4. **Filtros dinâmicos** (busca com campos opcionais) são construídos adicionando
   placeholders numerados a um `[]any` de argumentos — nunca interpolando o valor.
   Padrão: um helper `sqlbuilder` que só concatena fragmentos com `$N` e empilha
   os args.

5. **Contexto multitenant** (`app.organization_id`, `app.user_id`, `app.device_id`,
   `app.request_id`) é definido via `set_config($1, $2, true)` parametrizado
   dentro de `postgres.WithTenantTx` — jamais via `SET LOCAL ... = '<valor>'`
   concatenado.

6. **Migrations** são arquivos `.sql` estáticos, sem interpolação.

7. **Shell / psql:** nomes de banco são validados contra `^[a-z_][a-z0-9_]{0,62}$`
   e passados como `:"var"` (identificador). Senhas e outros valores usam `:'var'`
   (literal escapado pelo psql) + `format(%L, ...)` no plpgsql. Nada é montado por
   interpolação do shell no texto SQL.

## O que o `scripts/check-sql.sh` bloqueia

- `fmt.Sprintf(...)` / `+ "` / `"... "+` contendo palavras-chave SQL
  (`SELECT|INSERT|UPDATE|DELETE|WHERE|FROM|SET |set_config|VALUES|JOIN`).
- `db.Query`, `db.Exec`, `conn.Query*`, `tx.Query*`, `pool.Query*` cujo primeiro
  argumento não seja uma string literal (sinal de query montada).
- `SET LOCAL` seguido de `=` na mesma linha em arquivos `.go`.

Falso-positivo legítimo se resolve com um comentário `//nolint:sqlsafety` na
linha, justificado na revisão.

## Ferramentas

- `sqlc` gera acesso a dados tipado e parametrizado — é o caminho preferido.
- `go vet` + `staticcheck` no CI.
- `scripts/check-sql.sh` no CI e no `make lint`.
