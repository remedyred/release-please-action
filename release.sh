#!/bin/bash

set -e

# Auth
NPM_TOKEN=${NPM_TOKEN:-}
NPM_REGISTRY=${NPM_REGISTRY:-"//registry.npmjs.org/"}

[[ "$NPM_REGISTRY" =~ /$ ]] || NPM_REGISTRY="$NPM_REGISTRY/"
[[ "$NPM_REGISTRY" =~ ^// ]] || [[ "$NPM_REGISTRY" =~ ^https?:// ]] || NPM_REGISTRY="//$NPM_REGISTRY"

# Scripts
PUBLISH_SCRIPT=${PUBLISH_SCRIPT:-}

PRERELEASE_SCRIPTS=${PRERELEASE_SCRIPTS:-"build,lint,test,docs"}
IFS=', ' read -r -a PRERELEASE_SCRIPTS_ARRAY <<<"$PRERELEASE_SCRIPTS"

PUBLISH_COMMAND="pnpm publish --ignore-scripts"

# Configurations
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
DEBUG=${DEBUG:-false}
NO_BAIL=${NO_BAIL:-false}
BAIL_ON_MISSING=${BAIL_ON_MISSING:-false}

AVAILABLE_SCRIPTS=$(npm run > /dev/null 2>&1 || true)

# Check if npm script exists
#:: has_script <script_name>
has_script() {
  local script_name="$1"
  local SCRIPT_COUNT
  SCRIPT_COUNT=$(echo "$AVAILABLE_SCRIPTS" | grep -c "^  $script_name")
  [[ $SCRIPT_COUNT -gt 0 ]]
}

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

# Run the publish script
function publish() {
  if [[ -n "$PUBLISH_SCRIPT" ]]; then
    runScript "$PUBLISH_SCRIPT"
  elif [[ -n "$NPM_TOKEN" ]] && ! jq -e ".private" package.json >/dev/null; then
    if [ "$DRY_RUN" = true ] || [[ "$DRY_RUN" == "publish-only" ]]; then
      PUBLISH_COMMAND="$PUBLISH_COMMAND --dry-run"
    fi

    if [[ "$DEBUG" == "true" ]]; then
      echo "RUN: $PUBLISH_COMMAND"
    fi

    $PUBLISH_COMMAND
  fi
}

function install() {
  echo "Install dependencies"
  local PNPM_INSTALL_COMMAND="pnpm install"

  if [[ -f "pnpm-lock.yaml" ]]; then
    PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --frozen-lockfile"
  fi

  if [[ "$VERBOSE" != "true" ]]; then
    PNPM_INSTALL_COMMAND="$PNPM_INSTALL_COMMAND --silent"
  fi

  if [[ "$DEBUG" == "true" ]]; then
    echo "RUN: $PNPM_INSTALL_COMMAND"
  fi

  $PNPM_INSTALL_COMMAND
}

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

  if [[ "$VERIFY_ONLY" == "true" ]]; then
    echo "NPM authentication successful"
    exit 0
  fi
fi

install

for script in "${PRERELEASE_SCRIPTS_ARRAY[@]}"; do
  runScript "$script"
done

if [[ "$SKIP_PUBLISH" == "true" ]]; then
  echo "Finished!"
  exit 0
fi

publish
