#!/bin/bash

set -euo pipefail

INPUTS=${1:-}

# shellcheck source=./lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
[[ -v __IS_SETUP ]] || {
  echo "ERROR: common.sh not found"
  exit 1
}

# Set GitHub Actions as the user
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"

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

pnpm i -g release-please >/dev/null || die "Failed to install release-please"

success "NPM configuration verified"

info "Installing dependencies"
PNPM_INSTALL_COMMAND="pnpm install --loglevel error"

debug "RUN: $PNPM_INSTALL_COMMAND"
PNPM_ERROR=$(pnpm i --frozen-lockfile --loglevel error 2>&1)
PNPM_EXIT_CODE=$?
if ((PNPM_EXIT_CODE)); then
  if [[ "$PNPM_ERROR" =~ "ERR_PNPM_OUTDATED_LOCKFILE" ]] && [[ "$AUTOFIX_LOCKFILE" == "true" ]] && [[ "$CONFIG_ONLY" != "true" ]] && [[ "$PRERELEASE_ONLY" != "true" ]]; then
    debug "RUN: $PNPM_INSTALL_COMMAND --fix-lockfile"
    $PNPM_INSTALL_COMMAND --fix-lockfile
    git add pnpm-lock.yaml
    git commit -m "chore: update lockfile" -m "[skip ci]"
    git push
  else
    die "Failed to install dependencies. $PNPM_ERROR"
  fi
else
  success "Dependencies installed"
fi

if [[ "$CONFIG_ONLY" == "true" ]]; then
  success "Finished!"
  exit 0
fi

for script in "${PRERELEASE_SCRIPTS_ARRAY[@]}"; do
  runScript "$script"
done

if [[ "$PRERELEASE_ONLY" != "true" ]]; then
  echo "should-release=true" >>"$GITHUB_OUTPUT"

  if [[ -n "$RELEASE_COMMAND" ]]; then
    echo "release-command=$RELEASE_COMMAND" >>"$GITHUB_OUTPUT"
  fi
fi
