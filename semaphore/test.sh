#!/bin/bash
set -e

mix coveralls.json &&
npm --prefix assets test
bash <(curl -s https://codecov.io/bash) -t $SCREENS_CODECOV_TOKEN
