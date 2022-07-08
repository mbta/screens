#!/bin/bash
set -e -x

BUILD_TAG=${1}
TEMP_DIR=$(mktemp -d)
STATIC_DIR=$TEMP_DIR/static

# the ">" merely redirects the printout. It shushes it.
pushd "$TEMP_DIR" > /dev/null
# ls -al /home/screens
# ls -al /home/screens/priv
# ls -al /home/screens/priv/static
# ls -al /home/runner/work/screens/screens
# ls -al /home/runner/work/screens/screens/priv
sh -c "docker run --rm ${BUILD_TAG} tar -c /root/priv/static" | tar -x --strip-components 2
ls -al
popd > /dev/null

echo "now printing static"
ls -al "$STATIC_DIR"

# upload source maps to Sentry
SENTRY_RELEASE=$(npx @sentry/cli releases propose-version)
npx @sentry/cli releases files "$SENTRY_RELEASE" upload-sourcemaps "$STATIC_DIR/js"
