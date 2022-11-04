#!/bin/bash

__LOADED=1
export __LOADED

# Auth
export NPM_TOKEN=${NPM_TOKEN:-}
export NPM_REGISTRY=${NPM_REGISTRY:-"//registry.npmjs.org/"}

[[ "$NPM_REGISTRY" =~ /$ ]] || NPM_REGISTRY="$NPM_REGISTRY/"
[[ "$NPM_REGISTRY" =~ ^// ]] || [[ "$NPM_REGISTRY" =~ ^https?:// ]] || NPM_REGISTRY="//$NPM_REGISTRY"

# Scripts
export PUBLISH_SCRIPT=${PUBLISH_SCRIPT:-}

PRERELEASE_SCRIPTS=${PRERELEASE_SCRIPTS:-"build,lint,test,docs"}
IFS=', ' read -r -a PRERELEASE_SCRIPTS_ARRAY <<<"$PRERELEASE_SCRIPTS"
export PRERELEASE_SCRIPTS_ARRAY

# Configurations
export DRY_RUN=${DRY_RUN:-false}
export DEBUG=${DEBUG:-false}
export NO_BAIL=${NO_BAIL:-false}
export BAIL_ON_MISSING=${BAIL_ON_MISSING:-false}
AVAILABLE_SCRIPTS=$(npm run > /dev/null 2>&1 || true)
export AVAILABLE_SCRIPTS

# Check if npm script exists
#:: has_script <script_name>
has_script() {
  local script_name="$1"
  jq ".scripts | has(\"$script_name\")" package.json
}
export -f has_script

# Run npm script
#:: run_script <script_name>
runScript() {
  local script_name="$1"
  local PNPM_RUN_COMMAND="pnpm run --if-present"

  if has_script "$script_name"; then
    debug "Running $script_name"

    if [[ "$DEBUG" != "true" ]]; then
      PNPM_RUN_COMMAND="$PNPM_RUN_COMMAND --silent"
    fi

    if [[ "$NO_BAIL" == "true" ]]; then
      PNPM_RUN_COMMAND="$PNPM_RUN_COMMAND --no-bail"
    fi

    PNPM_RUN_COMMAND="$PNPM_RUN_COMMAND $script_name"

    if [[ "$DRY_RUN" == "true" ]]; then
      info "[DRY RUN] $PNPM_RUN_COMMAND"
    else
      debug "RUN: $PNPM_RUN_COMMAND"
      $PNPM_RUN_COMMAND
    fi
  else
    if [[ "$BAIL_ON_MISSING" == "true" ]]; then
      error "No script found for $script_name"
      exit 1
    else
      warn "No script found for $script_name"
    fi
  fi
}
export -f runScript

debug () {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "\033[0;33m[DEBUG]\033[0m $1"
  fi
}
export -f debug

info() {
  echo -e "\033[0;32m[INFO]\033[0m $1"
}
export -f info

warn() {
  echo -e "\033[0;33m[WARN]\033[0m $1"
}
export -f warn

error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}
export -f error

success () {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}
export -f success

log () {
  echo -e "\033[0;37m[LOG]\033[0m $1"
}
export -f log

debug "DRY_RUN: $DRY_RUN"
debug "DEBUG: $DEBUG"
debug "NO_BAIL: $NO_BAIL"
debug "BAIL_ON_MISSING: $BAIL_ON_MISSING"
debug "PUBLISH_SCRIPT: $PUBLISH_SCRIPT"
debug "PRERELEASE_SCRIPTS: $PRERELEASE_SCRIPTS"
debug "AVAILABLE_SCRIPTS:\n$AVAILABLE_SCRIPTS"
