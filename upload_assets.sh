#!/bin/bash
set -e -x

BUILD_TAG=${1}
TEMP_DIR=$(mktemp -d)
STATIC_DIR=$TEMP_DIR/static

pushd "$TEMP_DIR" > /dev/null
sh -c "docker run --rm ${BUILD_TAG} tar -c /root/priv/static" | tar -x --strip-components 2
popd > /dev/null

# upload source maps to Sentry
SENTRY_RELEASE=$(npx @sentry/cli releases propose-version)
npx @sentry/cli releases files "$SENTRY_RELEASE" upload-sourcemaps "$STATIC_DIR/js"
