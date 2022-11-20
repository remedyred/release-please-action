#!/bin/bash

set -euo pipefail

INPUTS=${1:-}
RELEASES=${2:-}

# shellcheck source=./lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh" || {
  echo "Failed to load common.sh"
  exit 1
}

# Double check that we don't run this script during prerelease only, or config only workflows
if [[ "$PRERELEASE_ONLY" == "true" ]] || [[ "$CONFIG_ONLY" == "true" ]]; then
  success "Finished!"
  exit 0
fi

# Run the publish script
function publish() {
  local PUBLISH_COMMAND="pnpm publish --ignore-scripts"
  if [[ -n "$PUBLISH_SCRIPT" ]]; then
    runScript "$PUBLISH_SCRIPT"
  elif [[ -z "$NPM_TOKEN" ]]; then
    warn "No NPM_TOKEN set, skipping publish"
  elif jq -e ".private" package.json >/dev/null; then
    warn "Skipping publish for private package"
  else
    if [ "$DRY_RUN" = true ] || [[ "$DRY_RUN" == "publish-only" ]]; then
      PUBLISH_COMMAND="$PUBLISH_COMMAND --dry-run"
    fi

    debug "RUN: $PUBLISH_COMMAND"
    $PUBLISH_COMMAND
  fi
}

REBUILD=0
BASE_PATH=$(pwd)
[[ -f "turbo.json" ]] || REBUILD=1

echo "$RELEASES" | jq -r '.[]' | while read -r package_dir; do
  if [[ "$package_dir" == "." ]]; then
    cd "$BASE_PATH" || die "Could not cd into repo root"
  else
    cd "$BASE_PATH/$package_dir" || die "Could not cd into $package_dir"
  fi

  if ((REBUILD)) && [[ "$package_dir" != "." ]]; then
    debug "Checking for build script in $package_dir"
    runScript "build"
  fi

  debug "Publishing $package_dir"
  publish
  success "Published $package_dir"
done

success "Finished!"
