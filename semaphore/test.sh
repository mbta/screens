#!/bin/bash
set -e

mix coveralls.json &&
npm --prefix assets test
