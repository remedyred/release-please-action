#!/bin/bash

set -euxo pipefail

INPUTS=${1:-}
GITHUB_REPOSITORY=${2:-}

# shellcheck source=./lib/common.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
[[ -v __IS_SETUP ]] || {
  echo "ERROR: common.sh not found"
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

# Run release-please
RELEASE_PLEASE_BASE_PARAMS=()
RELEASE_PLEASE_BASE_PARAMS+=("--token=$GITHUB_TOKEN")
RELEASE_PLEASE_BASE_PARAMS+=("--repo-url=$GITHUB_REPOSITORY")
[[ "$DRY_RUN" == "true" ]] || [[ "$DRY_RUN" == "publish-only" ]] && RELEASE_PLEASE_BASE_PARAMS+=("--dry-run")
[[ "$DEBUG" == "true" ]] && RELEASE_PLEASE_BASE_PARAMS+=("--debug")

info "Found packages: ${PACKAGES[*]}"

REBUILD=0
BASE_PATH=$(pwd)
[[ -f "turbo.json" ]] || REBUILD=1

for PACKAGE in $PACKAGES; do

  if ((REBUILD)) && [[ "$PACKAGE" != "$BASE_PATH" ]]; then
    debug "Checking for build script in $PACKAGE"
    runScript "build"
  fi

  info "Running release-please for $PACKAGE"
  packageName=$(jq -r ".name" "$PACKAGE"/package.json)

  # set RELEASE_PLEASE_PATH to PACKAGE relative to repo root
  RELEASE_PLEASE_PATH=$(realpath --relative-to="$BASE_PATH" "$PACKAGE")

  RELEASE_PLEASE_PARAMS=("${RELEASE_PLEASE_BASE_PARAMS[@]}")
  RELEASE_PLEASE_PARAMS+=("--path=$RELEASE_PLEASE_PATH")
  RELEASE_PLEASE_PARAMS+=("--package-name=$packageName")
  RELEASE_PLEASE_PARAMS+=(--monorepo-tags)
  RELEASE_PLEASE_PARAMS+=(--pull-request-title-pattern="chore: release $packageName \${version}")

  debug "RUN: release-please github-release ${RELEASE_PLEASE_PARAMS[*]}"
  release-please github-release "${RELEASE_PLEASE_PARAMS[@]}" || die "release-please failed to create a GitHub release"

  debug "RUN: release-please release-pr ${RELEASE_PLEASE_PARAMS[*]}"
  release-please release-pr "${RELEASE_PLEASE_PARAMS[@]}" || die "release-please failed to create a release PR"
done

success "Finished!"
