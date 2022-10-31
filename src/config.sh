#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=./common.sh
((__LOADED)) || . "$SCRIPT_DIR"/common.sh

if [[ -n "$NPM_TOKEN" ]]; then
  # Set NPM_TOKEN
  echo "Configuring NPM authentication"

  NPM_CONFIG_COMMAND="npm config set $NPM_REGISTRY $NPM_TOKEN"

  if [[ "$DEBUG" == "true" ]]; then
    echo "RUN: $NPM_CONFIG_COMMAND"
  fi

  $NPM_CONFIG_COMMAND

  if ! npm whoami >/dev/null; then
    echo "NPM authentication failed"
    exit 1
  fi
else
  echo "No NPM_TOKEN provided, skipping NPM authentication"
fi

if [[ "$CONFIG_ONLY" == "true" ]]; then
  echo "NPM configuration verified"
  exit 0
fi
