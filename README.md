# postgres

A imagem oficial do [pgvector](https://github.com/pgvector/pgvector) com a
extensão [`pg_search`](https://github.com/paradedb/paradedb) da ParadeDB, o
índice BM25 da busca de texto. Nada mais muda: é a mesma base, com um pacote a
mais e o comando que o carrega.

```
lucaspeixotoadv/postgres:pg16-bookworm-pgvector-0.8.7-pg_search-0.26.1
```

## A tag

O nome é genérico; a tag diz o que a imagem tem, cada parte com a versão:

| Parte | O que é |
|---|---|
| `pg16` | a versão maior do Postgres |
| `bookworm` | o Debian da base (a glibc, a ordenação de texto) |
| `pgvector-0.8.7` | a versão do pgvector |
| `pg_search-0.26.1` | a versão do `pg_search` |

As versões estão nos `ARG` do [`Dockerfile`](Dockerfile), e o workflow de
publicação monta a tag a partir deles. Mudar qualquer versão publica outra tag;
uma tag publicada nunca é sobrescrita.

## Subir sobre um volume existente

O volume de um Postgres que roda `pgvector/pgvector` com a **mesma** versão
maior, o **mesmo** Debian e o **mesmo** pgvector sobe nesta imagem sem dump,
restore nem REINDEX. Com qualquer uma delas diferente, não: confira antes
(`cat /etc/os-release` no container e
`SELECT extversion FROM pg_extension WHERE extname = 'vector';`).

A imagem sozinha não muda o banco: a extensão só passa a existir nele com
`CREATE EXTENSION pg_search`, que é da aplicação.

## O comando

A imagem sobe com:

```
postgres -c shared_preload_libraries=pg_search -c paradedb.planner_warnings=off
```

Nada disso fica gravado no volume. Quem sobrescreve o `command` do container
precisa levar os dois parâmetros, e juntar `pg_search` às bibliotecas que já
carrega: `shared_preload_libraries=pg_stat_statements,pg_search`. O parâmetro
da linha de comando substitui o do `postgresql.conf` e o de `ALTER SYSTEM`.

## Voltar para a imagem sem a extensão

Primeiro tire do banco tudo o que depende dela (os índices BM25 e a extensão,
pela aplicação), e só então troque a imagem. Trocar antes sobe o Postgres, mas
toda consulta a uma tabela com índice BM25 falha
(`could not access file "$libdir/pg_search"`).

## Publicar

Pelo "Run workflow" do workflow **Publish**, depois de mudar as versões no
`Dockerfile`. Precisa dos segredos `DOCKERHUB_USERNAME` e `DOCKERHUB_TOKEN`.

## Licenças

O `pg_search` é da ParadeDB, sob a [AGPL v3](https://github.com/paradedb/paradedb/blob/main/LICENSE),
distribuído aqui sem alteração, pelo pacote oficial do
[release](https://github.com/paradedb/paradedb/releases) da versão da tag. O
código-fonte está no repositório da ParadeDB, na tag `v<versão>`. O pgvector e o
Postgres seguem as licenças deles.
