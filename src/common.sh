#!/bin/bash

__LOADED=1

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
export VERBOSE=${VERBOSE:-false}
export DEBUG=${DEBUG:-false}
export NO_BAIL=${NO_BAIL:-false}
export BAIL_ON_MISSING=${BAIL_ON_MISSING:-false}

AVAILABLE_SCRIPTS=$(npm run > /dev/null 2>&1 || true)
export AVAILABLE_SCRIPTS


# Check if npm script exists
#:: has_script <script_name>
has_script() {
  local script_name="$1"
  local SCRIPT_COUNT
  SCRIPT_COUNT=$(echo "$AVAILABLE_SCRIPTS" | grep -c "^  $script_name")
  [[ $SCRIPT_COUNT -gt 0 ]]
}
export -f has_script

# Run npm script
#:: run_script <script_name>
runScript() {
  local script_name="$1"
  local PNPM_RUN_COMMAND="pnpm run --if-present"

  if has_script "$script_name"; then
    echo "Running $script_name"

    if [[ "$VERBOSE" != "true" ]]; then
      PNPM_RUN_COMMAND="$PNPM_RUN_COMMAND --silent"
    fi

    if [[ "$NO_BAIL" == "true" ]]; then
      PNPM_RUN_COMMAND="$PNPM_RUN_COMMAND --no-bail"
    fi

    PNPM_RUN_COMMAND="$PNPM_RUN_COMMAND $script_name"

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "[DRY RUN] $PNPM_RUN_COMMAND"
    else
      if [[ "$DEBUG" == "true" ]]; then
        echo "RUN: $PNPM_RUN_COMMAND"
      fi

      $PNPM_RUN_COMMAND
    fi
  else
    echo "No script found for $script_name"

    if [[ "$BAIL_ON_MISSING" == "true" ]]; then
      exit 1
    fi
  fi
}
export -f runScript
