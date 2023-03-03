#!/bin/bash

[[ -v __IS_SETUP ]] && return 0
export __IS_SETUP=1

LIB="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=./output.sh
. "$LIB/output.sh"

# shellcheck source=./scripts.sh
. "$LIB/scripts.sh"

# Load vars from json
[[ -n $INPUTS ]] || die "No JSON file specified"

NPM_TOKEN=$(echo "$INPUTS" | jq -r '.NPM_TOKEN')
GITHUB_TOKEN=$(echo "$INPUTS" | jq -r '.GITHUB_TOKEN')
NPM_REGISTRY=$(echo "$INPUTS" | jq -r '.NPM_REGISTRY')
PUBLISH_SCRIPT=$(echo "$INPUTS" | jq -r '.PUBLISH_SCRIPT')
PRERELEASE_SCRIPTS=$(echo "$INPUTS" | jq -r '.PRERELEASE_SCRIPTS')
NO_BAIL=$(echo "$INPUTS" | jq -r '.NO_BAIL')
BAIL_ON_MISSING=$(echo "$INPUTS" | jq -r '.BAIL_ON_MISSING')
DRY_RUN=$(echo "$INPUTS" | jq -r '.DRY_RUN')
DEBUG=$(echo "$INPUTS" | jq -r '.DEBUG')
CONFIG_ONLY=$(echo "$INPUTS" | jq -r '.CONFIG_ONLY')
PRERELEASE_ONLY=$(echo "$INPUTS" | jq -r '.PRERELEASE_ONLY')
AUTOFIX_LOCKFILE=$(echo "$INPUTS" | jq -r '.AUTOFIX_LOCKFILE')
MONOREPO=$(echo "$INPUTS" | jq -r '.MONOREPO')
RELEASE_COMMAND=$(echo "$INPUTS" | jq -r '.RELEASE_COMMAND')

# Process Vars

[[ -z "$NPM_REGISTRY" ]] && NPM_REGISTRY="//registry.npmjs.org/"
[[ "$NPM_REGISTRY" =~ /$ ]] || NPM_REGISTRY="$NPM_REGISTRY/"
[[ "$NPM_REGISTRY" =~ ^// ]] || [[ "$NPM_REGISTRY" =~ ^https?:// ]] || NPM_REGISTRY="//$NPM_REGISTRY"

PRERELEASE_SCRIPTS=${PRERELEASE_SCRIPTS:-"build,lint,test,docs"}
IFS=', ' read -r -a PRERELEASE_SCRIPTS_ARRAY <<<"$PRERELEASE_SCRIPTS"

AVAILABLE_SCRIPTS=$(npm run >/dev/null 2>&1 || true)

[[ -z "$DRY_RUN" ]] && DRY_RUN=false
[[ -z "$DEBUG" ]] && DEBUG=false
[[ -z "$NO_BAIL" ]] && NO_BAIL=false
[[ -z "$BAIL_ON_MISSING" ]] && BAIL_ON_MISSING=false
[[ -z "$AUTOFIX_LOCKFILE" ]] && AUTOFIX_LOCKFILE=true
[[ -z "$CONFIG_ONLY" ]] && CONFIG_ONLY=false
[[ -z "$PRERELEASE_ONLY" ]] && PRERELEASE_ONLY=false

if [[ -z "$MONOREPO" ]] && [[ ${#PACKAGES[@]} -gt 1 ]]; then
  MONOREPO=true
else
  MONOREPO=false
fi

if [[ -z "$RELEASE_COMMAND" ]] && [[ "$MONOREPO" == "true" ]]; then
  RELEASE_COMMAND="manifest"
fi

debug "DRY_RUN: $DRY_RUN"
debug "DEBUG: $DEBUG"
debug "NO_BAIL: $NO_BAIL"
debug "CONFIG_ONLY: $CONFIG_ONLY"
debug "PRERELEASE_ONLY: $PRERELEASE_ONLY"
debug "MONOREPO: $MONOREPO"
debug "BAIL_ON_MISSING: $BAIL_ON_MISSING"
debug "AUTOFIX_LOCKFILE: $AUTOFIX_LOCKFILE"
debug "PUBLISH_SCRIPT: $PUBLISH_SCRIPT"
debug "RELEASE_COMMAND: $RELEASE_COMMAND"
debug "PRERELEASE_SCRIPTS: $PRERELEASE_SCRIPTS"
debug "AVAILABLE_SCRIPTS:\n$AVAILABLE_SCRIPTS"

# Auth
export GITHUB_TOKEN
export NPM_TOKEN
export NPM_REGISTRY

# Scripts
export PUBLISH_SCRIPT
export PRERELEASE_SCRIPTS_ARRAY
export AVAILABLE_SCRIPTS

# Configurations
export DRY_RUN
export DEBUG
export NO_BAIL
export BAIL_ON_MISSING

# Released Packages
export RELEASES
