#!/bin/bash
set -ex

mix do deps.get, credo --strict
