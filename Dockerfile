# first, get the elixir dependencies within an elixir container
# we use a container from the Hex team in order to pin the Erlang and OS versions as well
FROM hexpm/elixir:1.12.1-erlang-24.0.2-debian-buster-20210326 as elixir-builder

ENV LANG="C.UTF-8" MIX_ENV="prod"

WORKDIR /root
ADD . .

RUN mix do local.hex --force, local.rebar --force
RUN mix do deps.get --only prod

# next, build the frontend assets within a node.js container
FROM node:14-buster as assets-builder

WORKDIR /root
ADD . .

# copy in elixir deps required to build node modules for phoenix
COPY --from=elixir-builder /root/deps ./deps

RUN npm --prefix assets ci
RUN npm --prefix assets run deploy

# now, build the application back in the elixir container
FROM elixir-builder as app-builder

ENV LANG="C.UTF-8" MIX_ENV="prod"

WORKDIR /root

# add frontend assets compiled in node container, required by phx.digest
COPY --from=assets-builder /root/priv/static ./priv/static

RUN mix do compile --force, phx.digest, release

# finally, use a debian container for the runtime environment
FROM debian:buster

ENV MIX_ENV="prod" TERM="xterm" LANG="C.UTF-8" PORT="4000"

WORKDIR /root
ADD . .

# erlang-crypto requires system library libssl1.1
RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl1.1 \
  && rm -rf /var/lib/apt/lists/*

# add frontend assets with manifests from app build container
COPY --from=app-builder /root/priv/static ./priv/static
# add application artifact comipled in app build container
COPY --from=app-builder /root/_build/prod/rel/screens .

# run the application
CMD ["bin/screens", "start"]
