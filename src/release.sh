#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=./common.sh
((__LOADED)) || . "$SCRIPT_DIR"/common.sh

# Run the publish script
function publish() {
  local PUBLISH_COMMAND="pnpm publish --ignore-scripts"
  if [[ -n "$PUBLISH_SCRIPT" ]]; then
    runScript "$PUBLISH_SCRIPT"
  elif [[ -z "$NPM_TOKEN" ]]; then
    warn "No NPM_TOKEN set, skipping publish"
  elif jq -e ".private" package.json >/dev/null; then
    warn "Skipping publish for private package"
  else
    if [ "$DRY_RUN" = true ] || [[ "$DRY_RUN" == "publish-only" ]]; then
      PUBLISH_COMMAND="$PUBLISH_COMMAND --dry-run"
    fi

    debug "RUN: $PUBLISH_COMMAND"
    $PUBLISH_COMMAND
  fi
}

function install() {
  info "Installing dependencies"
  local PNPM_INSTALL_COMMAND="pnpm install"

  if [[ -f "pnpm-lock.yaml" ]]; then
    PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --frozen-lockfile"
  fi

  if [[ "$DEBUG" != "true" ]]; then
    PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --silent"
  fi

  debug "RUN: $PNPM_INSTALL_COMMAND"
  $PNPM_INSTALL_COMMAND
}

# shellcheck source=./verify.sh
. "$SCRIPT_DIR"/verify.sh

if [[ "$SKIP_PUBLISH" == "true" ]]; then
  success "Finished!"
  exit 0
fi

publish
