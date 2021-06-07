#!/bin/bash
set -e

ELIXIR_VERSION=1.12.1
ERLANG_VERSION=24.0.2
NODE_JS_VERSION=14.11

MAX_ERLANG_INSTALL_ATTEMPTS=3
erlang_install_attempt=1

change-phantomjs-version 2.1.1

nvm install $NODE_JS_VERSION --latest-npm

export ERL_HOME="${SEMAPHORE_CACHE_DIR}/.kerl/installs/${ERLANG_VERSION}"

if [ ! -d "${ERL_HOME}" ]; then
    mkdir -p "${ERL_HOME}"
    until KERL_BUILD_BACKEND=git kerl build $ERLANG_VERSION $ERLANG_VERSION || (( erlang_install_attempt == MAX_ERLANG_INSTALL_ATTEMPTS ))
    do
    	echo "Failed to build erlang, trying again in 5 seconds..."
    	((erlang_install_attempt++))
    	sleep 5
    done
    kerl install $ERLANG_VERSION $ERL_HOME
fi

. $ERL_HOME/activate

if ! kiex use $ELIXIR_VERSION; then
    kiex install $ELIXIR_VERSION
    kiex use $ELIXIR_VERSION
fi

mix local.hex --force
mix local.rebar --force
mix deps.get

npm --prefix assets ci
