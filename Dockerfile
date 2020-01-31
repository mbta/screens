# build the frontend assets within a node.js container
FROM node:13 as assets-builder

WORKDIR /root
ADD . .

RUN npm --prefix assets ci
RUN npm --prefix assets run deploy

# build the application within an elixir container
FROM elixir:1.9.4 as elixir-builder

ENV LANG="C.UTF-8" MIX_ENV="prod"

WORKDIR /root
ADD . .

RUN mix do local.hex --force, local.rebar --force
RUN mix do deps.get --only prod, compile --force, phx.digest, release

# use a debian container for the runtime environment
FROM debian:buster

# set up runtime environment configuration
WORKDIR /root
EXPOSE 4000
ENV MIX_ENV="prod" TERM="xterm" LANG="C.UTF-8" PORT="4000"

# erlang-crypto requires system library libssl1.1
RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl1.1 \
  && rm -rf /var/lib/apt/lists/*

# add frontend assets compiled in node container
COPY --from=assets-builder /root/priv/static ./static
# add application artifact compiled in elixir container
COPY --from=elixir-builder /root/_build/prod/rel/screens .

# run the application
CMD ["bin/screens", "start"]
