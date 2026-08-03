ARG ALPINE_VERSION=3.21.3
ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.3.4
ARG NODE_VERSION=22.18.0


# --- Set up Elixir app builder

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS elixir-builder

ENV MIX_ENV="prod"
ENV DATABASE_USER=""
ENV DATABASE_PASSWORD=""
WORKDIR /root
ADD . .

RUN apk add --update git make
RUN mix do local.hex --force, local.rebar --force
RUN mix do deps.get --only prod


# --- Build frontend assets

FROM node:${NODE_VERSION} AS assets-builder

WORKDIR /root
ADD . .

# copy in elixir deps, required to build node modules for phoenix
COPY --from=elixir-builder /root/deps ./deps

RUN npm --prefix assets ci
RUN npm --prefix assets run deploy


# --- Build final application

FROM elixir-builder AS app-builder

RUN apk add --update curl

ENV MIX_ENV="prod"
WORKDIR /root

RUN curl https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o aws-cert-bundle.pem -f

# add frontend assets built earlier, required by phx.digest
COPY --from=assets-builder /root/priv/static ./priv/static

RUN mix do compile --force, phx.digest, sentry.package_source_code, release


# --- Set up runtime container and copy built app into it

FROM hexpm/erlang:${ERLANG_VERSION}-alpine-${ALPINE_VERSION}

ENV MIX_ENV="prod" PORT="4000"
WORKDIR /root
ADD . .

COPY --from=app-builder /root/priv/static ./priv/static
COPY --from=app-builder /root/_build/prod/rel/screens .

COPY --from=app-builder /root/aws-cert-bundle.pem ./priv/aws-cert-bundle.pem

CMD ["bin/screens", "start"]
