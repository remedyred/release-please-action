#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=./common.sh
((__LOADED)) || . "$SCRIPT_DIR"/common.sh

PUBLISH_COMMAND="pnpm publish --ignore-scripts"

# Run the publish script
function publish() {
  if [[ -n "$PUBLISH_SCRIPT" ]]; then
    runScript "$PUBLISH_SCRIPT"
  elif [[ -z "$NPM_TOKEN" ]]; then
    echo "No NPM_TOKEN set, skipping publish"
  elif jq -e ".private" package.json >/dev/null; then
    echo "Skipping publish for private package"
  else
    if [ "$DRY_RUN" = true ] || [[ "$DRY_RUN" == "publish-only" ]]; then
      PUBLISH_COMMAND="$PUBLISH_COMMAND --dry-run"
    fi

    if [[ "$DEBUG" == "true" ]]; then
      echo "RUN: $PUBLISH_COMMAND"
    fi

    $PUBLISH_COMMAND
  fi
}

function install() {
  echo "Install dependencies"
  local PNPM_INSTALL_COMMAND="pnpm install"

  if [[ -f "pnpm-lock.yaml" ]]; then
    PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --frozen-lockfile"
  fi

  if [[ "$DEBUG" != "true" ]]; then
    PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --silent"
  fi

  if [[ "$DEBUG" == "true" ]]; then
    echo "RUN: $PNPM_INSTALL_COMMAND"
  fi

  $PNPM_INSTALL_COMMAND
}

# shellcheck source=./verify.sh
. "$SCRIPT_DIR"/verify.sh

if [[ "$SKIP_PUBLISH" == "true" ]]; then
  echo "Finished!"
  exit 0
fi

publish
