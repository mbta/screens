#!/bin/bash
set -e

mix coveralls.json &&
npm --prefix assets test
# bash <(curl -s https://codecov.io/bash) -t $ARROW_CODECOV_TOKEN
