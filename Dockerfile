# first, get the elixir dependencies within an Elixir + Alpine Linux container
FROM hexpm/elixir:1.13.1-erlang-24.2-alpine-3.15.0 AS elixir-builder

ENV LANG="C.UTF-8" MIX_ENV="prod"

WORKDIR /root
ADD . .

# Install Hex+Rebar
RUN mix do local.hex --force, local.rebar --force
RUN mix do deps.get --only prod

# Install git
RUN apk --update add git make

# next, build the frontend assets within a Node.JS container
FROM node:14 as assets-builder

WORKDIR /root
ADD . .

# copy in elixir deps required to build node modules for phoenix
COPY --from=elixir-builder /root/deps ./deps

RUN npm --prefix assets ci
RUN npm --prefix assets run deploy

# now, build the application back in the Elixir + Alpine container
FROM elixir-builder as app-builder

ENV LANG="C.UTF-8" MIX_ENV="prod"

WORKDIR /root

# add frontend assets compiled in node container, required by phx.digest
COPY --from=assets-builder /root/priv/static ./priv/static

RUN mix do compile --force, phx.digest, release

# finally, use an Alpine container for the runtime environment
FROM alpine:3.15.0

ENV MIX_ENV="prod" TERM="xterm" LANG="C.UTF-8" PORT="4000"

WORKDIR /root
ADD . .

RUN apk --update add \
  # erlang-crypto requires system library libssl1.1
  libssl1.1 \
  # Erlang/OTP 24+ requires a glibc version that ships with asmjit
  libstdc++ libgcc \
  # Clean up the package cache after install
  && rm -rf /var/cache/apk

# add frontend assets with manifests from app build container
COPY --from=app-builder /root/priv/static ./priv/static
# add application artifact comipled in app build container
COPY --from=app-builder /root/_build/prod/rel/screens .

# Ensure SSL support is enabled
RUN bin/screens eval ":crypto.supports()"

# run the application
CMD ["bin/screens", "start"]
