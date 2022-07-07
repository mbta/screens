#!/bin/bash
set -e -x

BUILD_TAG=${1}
TEMP_DIR=$(mktemp -d)
STATIC_DIR=$TEMP_DIR/priv/static

# the ">" merely redirects the printout. It shushes it.
pushd "$TEMP_DIR" > /dev/null
# ls -al /home/screens
# ls -al /home/screens/priv
# ls -al /home/screens/priv/static
ls -al /home/runner/work/screens/screens
ls -al /home/runner/work/screens/screens/priv
sh -c "docker run --rm ${BUILD_TAG} tar -c /home/runner/work/screens/screens/priv/static" | tar -x --strip-components 2
popd > /dev/null

echo "just printing out the current directory and contents"
ls -al

echo "now printing the static dir / js"
ls -al "$STATIC_DIR/js"

# upload source maps to Sentry
SENTRY_RELEASE=$(npx @sentry/cli releases propose-version)
npx @sentry/cli releases files "$SENTRY_RELEASE" upload-sourcemaps "$STATIC_DIR/js"
