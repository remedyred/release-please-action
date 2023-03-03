#!/bin/bash

set -euo pipefail

INPUTS=${1:-}

# shellcheck source=./lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh" || {
  echo "Failed to load common.sh"
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

autoBootstrap() {
    if [[ ! -f "pnpm-workspace.yml" ]] && [[ ! -f "pnpm-workspace.yml" ]]; then
        warn "Only PNPM workspaces are supported"
        return
    fi

    info "Looking for packages to bootstrap"
    local packages="$(pnpm ls -r --depth -1 --parseable)"
    # skip the first package, since it's the root
    echo "$packages" | tail -n +2

    # check if these packages are in the release-please-config.json
    # if not, add them

    for package in $packages; do
        local package_name="$(basename $package)"
        local package_path="$(dirname $package)"
        local package_config="$(jq -r ".packages.\"$package_name\"" release-please-config.json)"
        if [[ "$package_config" == "null" ]]; then
            info "Adding $package_name to release-please-config.json"
            jq ".packages.\"$package_name\" = {}" release-please-config.json > release-please-config.json.tmp
            mv release-please-config.json.tmp release-please-config.json
            info "Committing release-please-config.json"
            git add release-please-config.json
            git commit -m "chore: add $package_name to release-please-config.json [skip ci]"
            info "Pushing release-please-config.json"
            git push
        fi
    done
}

if [[ "$AUTO_BOOTSTRAP" == "true" ]] && [[ "$MONOREPO" == "TRUE" ]]; then
    autoBootstrap
fi

for script in "${PRERELEASE_SCRIPTS_ARRAY[@]}"; do
  runScript "$script"
done

if [[ ("$AUTO_COMMIT" == "true" && "$PRERELEASE_ONLY" != "true") || "$AUTO_COMMIT_PRERELEASE" == "true" ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    # commit untracked changes created during prerelease, before moving into the release script
    git add .
    git commit -m "$AUTO_COMMIT_MESSAGE" -m "[skip ci]"
    git push
  fi
fi

# Outputs
if [[ "$PRERELEASE_ONLY" != "true" ]]; then
  echo "should-release=true" >>"$GITHUB_OUTPUT"

  if [[ -n "$RELEASE_COMMAND" ]]; then
    echo "release-command=$RELEASE_COMMAND" >>"$GITHUB_OUTPUT"
  fi
fi
