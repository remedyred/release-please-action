#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
INPUTS=${1:-}

# shellcheck source=./common.sh
((__LOADED)) || . "$SCRIPT_DIR"/common.sh

if [[ -n "$NPM_TOKEN" ]]; then
  # Set NPM_TOKEN
  info "Configuring NPM authentication"

  NPM_CONFIG_REGISTRY_COMMAND="npm config set registry https:$NPM_REGISTRY"
  debug "RUN: $NPM_CONFIG_REGISTRY_COMMAND"
  $NPM_CONFIG_REGISTRY_COMMAND || die "Failed to set NPM registry"

  NPM_CONFIG_TOKEN_COMMAND="npm config set $NPM_REGISTRY:_authToken $NPM_TOKEN"
  debug "RUN: $NPM_CONFIG_TOKEN_COMMAND"
  $NPM_CONFIG_TOKEN_COMMAND || die "Failed to set NPM token"

  debug "RUN: npm whoami"
  npm whoami >/dev/null || die "Failed to authenticate with NPM"
else
  warn "No NPM_TOKEN provided, skipping NPM authentication"
fi

success "NPM configuration verified"

info "Installing dependencies"
PNPM_INSTALL_COMMAND="pnpm install"

if [[ -f "pnpm-lock.yaml" ]]; then
  PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --frozen-lockfile"
fi

if [[ "$DEBUG" != "true" ]]; then
  PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --silent"
fi

debug "RUN: $PNPM_INSTALL_COMMAND"
$PNPM_INSTALL_COMMAND

if [[ "$CONFIG_ONLY" == "true" ]]; then
  success "Finished!"
  exit 0
fi

for script in "${PRERELEASE_SCRIPTS_ARRAY[@]}"; do
  runScript "$script"
done

exit 0
