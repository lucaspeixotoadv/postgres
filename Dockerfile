# A imagem oficial do pgvector com a extensao `pg_search` da ParadeDB (o indice
# BM25 da busca de texto).
#
# A BASE E A IMAGEM OFICIAL DO PGVECTOR, e o que muda e uma biblioteca a mais.
# Por isso o volume de dados de um Postgres que ja roda a mesma base sobe aqui
# sem dump nem restore: mesma versao maior do Postgres (o mesmo formato em
# disco), mesmo Debian (a mesma glibc, a mesma ordenacao de texto, sem REINDEX)
# e o mesmo pgvector. Trocar a base pela imagem da ParadeDB (outro Debian, outro
# pgvector) quebraria essas garantias.
#
# NADA AQUI GRAVA NO VOLUME: o carregamento da extensao vem do comando do
# container, e nao do `postgresql.conf` nem de `ALTER SYSTEM`, que ficariam no
# volume e impediriam a imagem sem a extensao de subir nele.
#
# CADA VERSAO E UMA SO: os argumentos abaixo. O workflow de publicacao monta a
# tag deles (`.github/workflows/publish.yml`), e a tag diz o que a imagem tem.
ARG PG_MAJOR=16
ARG DEBIAN=bookworm
ARG PGVECTOR_VERSION=0.8.7

FROM pgvector/pgvector:${PGVECTOR_VERSION}-pg${PG_MAJOR}-${DEBIAN}

ARG PG_MAJOR
ARG DEBIAN
ARG PG_SEARCH_VERSION=0.26.1
ARG TARGETARCH

# O pacote declara as dependencias (`libopenblas0`), e o apt as instala junto.
ADD https://github.com/paradedb/paradedb/releases/download/v${PG_SEARCH_VERSION}/postgresql-${PG_MAJOR}-pg-search_${PG_SEARCH_VERSION}-1PARADEDB-${DEBIAN}_${TARGETARCH}.deb /tmp/pg_search.deb
RUN apt-get update \
  && apt-get install -y --no-install-recommends /tmp/pg_search.deb \
  && rm -rf /tmp/pg_search.deb /var/lib/apt/lists/*

# O `pg_search` so funciona carregado com o servidor. O comando vale para um
# volume novo e para um existente igualmente. Quem sobrescreve o comando do
# container precisa levar estes dois parametros, e juntar `pg_search` as
# bibliotecas que ja carrega (`shared_preload_libraries=a,pg_search`).
#
# Os avisos do planejador da extensao ("Aggregate Scan not used...") dizem a
# cada consulta qual otimizacao dela ficou de fora; nao sao erro, e iriam para
# o log do servidor e para cada conexao da aplicacao. Desligados aqui, no
# servidor, que e de onde eles vem.
CMD ["postgres", "-c", "shared_preload_libraries=pg_search", "-c", "paradedb.planner_warnings=off"]
