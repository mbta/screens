#!/bin/sh

# Syncs two environments S3 buckets and their config files.
# Can only go from prod -> dev <-> dev-green

set -eu

SCREENS_BUCKET_PREFIX="s3://mbta-screens/screens"
SCREENS_CONFIG_PREFIX="s3://mbta-ctd-config/screens/screens"
PENDING_SCREENS_CONFIG_PREFIX="s3://mbta-ctd-config/screens/pending-screens"

DELETE_FLAG=false
SOURCE_ENV=""
DEST_ENV=""

while getopts "Dhs:d:" opt; do
  case $opt in
  D)
    echo "Running with delete flag - will delete files in destination environment that do not exist in source enviornment"
    ;;
  s)
    SOURCE_ENV=$OPTARG
    ;;
  d)
    DEST_ENV=$OPTARG
    ;;
  h)
    echo "Usage: $0 [-D] -s <screens-env-source-name> -d <screens-env-dest-name>" >&2
    exit 0
    ;;
  *)
    echo "Usage: $0 [-D] -s <screens-env-source-name> -d <screens-env-dest-name>" >&2
    exit 1
    ;;
  esac
done

case $SOURCE_ENV in
prod | dev | dev-green) true ;;
*)
  echo "Usage: $0 [-D] -s <screens-env-source-name> -d <screens-env-dest-name>" >&2
  echo "<screens-env-source-name> should be one of the following: prod | dev | dev-green" >&2
  exit 1
  ;;
esac

case $DEST_ENV in
dev | dev-green) true ;;
*)
  echo "Usage: $0 [-D] -s <screens-env-source-name> -d <screens-env-dest-name>" >&2
  echo "<screens-env-dest-name> should be one of the following: dev | dev-green" >&2
  exit 1
  ;;
esac

SOURCE_BUCKET="$SCREENS_BUCKET_PREFIX-$SOURCE_ENV"
DEST_BUCKET="$SCREENS_BUCKET_PREFIX-$DEST_ENV"

SCREENS_SOURCE_JSON="$SCREENS_CONFIG_PREFIX-$SOURCE_ENV.json"
SCREENS_DEST_JSON="$SCREENS_CONFIG_PREFIX-$DEST_ENV.json"

PENDING_SCREENS_SOURCE_JSON="$PENDING_SCREENS_CONFIG_PREFIX-$SOURCE_ENV.json"
PENDING_SCREENS_DEST_JSON="$PENDING_SCREENS_CONFIG_PREFIX-$DEST_ENV.json"

printf '%s' "Copy *$SOURCE_ENV* screens assets and configs into *$DEST_ENV*? "
read -r answer
case $answer in
[Yy]*)
  # TODO: When infra gives us all access to the GetObjectTagging permissions, we can get rid of the --copy-props arg
  if [ "$DELETE_FLAG" = true ]; then
    aws s3 sync "$SOURCE_BUCKET" "$DEST_BUCKET" --exact-timestamps --delete --acl public-read --exclude LAST_DEPLOY --copy-props metadata-directive
  else
    aws s3 sync "$SOURCE_BUCKET" "$DEST_BUCKET" --exact-timestamps --acl public-read --exclude LAST_DEPLOY --copy-props metadata-directive
  fi
  aws s3 cp "$SCREENS_SOURCE_JSON" "$SCREENS_DEST_JSON"
  aws s3 cp "$PENDING_SCREENS_SOURCE_JSON" "$PENDING_SCREENS_DEST_JSON"
  ;;
*) echo "Did not copy from *$SOURCE_ENV* to *$DEST_ENV*" ;;
esac
