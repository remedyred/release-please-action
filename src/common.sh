#!/bin/bash

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
      die "No script found for $script_name"
    else
      warn "No script found for $script_name"
    fi
  fi
}
export -f runScript

debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "\033[0;33m[DEBUG]\033[0m $1"
  fi
}
export -f debug

info() {
  echo -e "\033[0;36m[INFO]\033[0m $1"
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

success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}
export -f success

log() {
  echo -e "\033[0;37m[LOG]\033[0m $1"
}
export -f log

die() {
  error "$1"
  exit 1
}

export __LOADED=${__LOADED:-0}

if ((__LOADED == 0)); then
  __LOADED=1

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
  [[ -z "$MONOREPO" ]] && MONOREPO=false

  debug "DRY_RUN: $DRY_RUN"
  debug "DEBUG: $DEBUG"
  debug "NO_BAIL: $NO_BAIL"
  debug "BAIL_ON_MISSING: $BAIL_ON_MISSING"
  debug "AUTOFIX_LOCKFILE: $AUTOFIX_LOCKFILE"
  debug "PUBLISH_SCRIPT: $PUBLISH_SCRIPT"
  debug "PRERELEASE_SCRIPTS: $PRERELEASE_SCRIPTS"
  debug "AVAILABLE_SCRIPTS:\n$AVAILABLE_SCRIPTS"
fi

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
