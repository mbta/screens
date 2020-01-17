#!/bin/bash
set -e -x

export MIX_ENV=test

mix do deps.get, deps.compile
mix compile --force --warnings-as-errors

mix coveralls.json -u

# TODO re-enable codecov when ready
# bash <(curl -s https://codecov.io/bash)
