#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=./common.sh
((__LOADED)) || . "$SCRIPT_DIR"/common.sh

if [[ -n "$NPM_TOKEN" ]]; then
  # Set NPM_TOKEN
  info "Configuring NPM authentication"

  NPM_CONFIG_REGISTRY_COMMAND="npm config set registry $NPM_REGISTRY"
  debug "RUN: $NPM_CONFIG_REGISTRY_COMMAND"
  $NPM_CONFIG_REGISTRY_COMMAND || {
    error "Failed to set NPM registry"
    exit 1
  }

  NPM_CONFIG_TOKEN_COMMAND="npm config set $NPM_REGISTRY:_authToken $NPM_TOKEN"
  debug "RUN: $NPM_CONFIG_TOKEN_COMMAND"
  $NPM_CONFIG_TOKEN_COMMAND || {
    error "Failed to set NPM token"
    exit 1
  }

  debug "RUN: npm whoami"
  if ! npm whoami >/dev/null; then
    error "NPM authentication failed"
    exit 1
  fi
else
  warn "No NPM_TOKEN provided, skipping NPM authentication"
fi

if [[ "$CONFIG_ONLY" == "true" ]]; then
  success "NPM configuration verified"
  exit 0
fi
