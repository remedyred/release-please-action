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
IFS=', ' read -r -a PRERELEASE_SCRIPTS_ARRAY <<< "$PRERELEASE_SCRIPTS"

PUBLISH_COMMAND="pnpm publish --ignore-scripts"

# Configurations
DRY_RUN=${DRY_RUN:-false}
VERBOSE=${VERBOSE:-false}
NO_BAIL=${NO_BAIL:-false}
BAIL_ON_MISSING=${BAIL_ON_MISSING:-false}


AVAILABLE_SCRIPTS=$(npm run)
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
  local silent="$2"

  local PARAMS=""

  if has_script "$script_name"; then
    echo "Running $script_name"

    if [[ "$VERBOSE" != "true" ]]; then
      PARAMS="$PARAMS --silent"
    fi

    if [[ "$NO_BAIL" != "true" ]]; then
      PARAMS="$PARAMS --no-bail"
    fi

    if [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] pnpm run $PARAMS $script_name"
    else
      pnpm run "$PARAMS $script_name"
    fi
  else
    echo "No script found for $script_name"

    if [ "$BAIL_ON_MISSING" = true ]; then
      exit 1
    fi
  fi
}

# Run the publish script
function publish() {
  if [[ -n "$PUBLISH_SCRIPT" ]]; then
    runScript "$PUBLISH_SCRIPT"
  elif [[ -n "$NPM_TOKEN" ]] && ! jq -e ".private" package.json > /dev/null; then
    if [ "$DRY_RUN" = true ] || [[ "$DRY_RUN" == "publish-only" ]]; then
      $PUBLISH_COMMAND --dry-run
    else
      $PUBLISH_COMMAND
    fi
  fi
}

if [[ -n "$NPM_TOKEN" ]]; then
  # Set NPM_TOKEN
  echo "Configuring NPM authentication"
  npm config set "$NPM_REGISTRY" "$NPM_TOKEN"
fi

echo "Install dependencies"
pnpm install --frozen-lockfile

for script in "${PRERELEASE_SCRIPTS_ARRAY[@]}"; do
  runScript "$script"
done

publish
