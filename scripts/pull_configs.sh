#!/bin/sh

# Copies live configuration from S3 to the local paths expected by
# `Screens.Config.Fetch.Local`.

set -eu

if [ $# -eq 0 ]; then
  echo "Usage: $0 <screens-env-name>" >&2
  exit 1
fi

case $1 in
  prod | dev | dev-green) true;;
  * )
    echo "Environment should be: prod | dev | dev-green" >&2
    exit 2
    ;;
esac

maybe_cp() {
  if [ -e "$2" ]; then
    printf '%s' "Overwrite $2? "
    read -r answer
    case $answer in
      [Yy]* ) aws s3 cp "$1" "$2";;
      * ) echo "Skipped.";;
    esac
  else
    aws s3 cp "$1" "$2"
  fi
}

maybe_cp s3://mbta-ctd-config/screens/screens-"$1".json priv/local.json
maybe_cp s3://mbta-ctd-config/screens/pending-screens-"$1".json priv/local_pending.json
maybe_cp s3://mbta-signs/config.json priv/signs_ui_config.json
