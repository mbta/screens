ARG ALPINE_VERSION=3.21.3
ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.3.4
ARG NODE_VERSION=18.20.2


# --- Set up Elixir app builder

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS elixir-builder

ENV MIX_ENV="prod"
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

ENV MIX_ENV="prod"
WORKDIR /root

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

CMD ["bin/screens", "start"]
