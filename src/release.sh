#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
INPUTS=${1:-}
GITHUB_REPOSITORY=${2:-}
RELEASES=${3:-}

# shellcheck source=./common.sh
[[ -v __LOADED ]] || . "$SCRIPT_DIR"/common.sh

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

for PACKAGE in $PACKAGES; do
  packageName=$(jq -r ".name" "$PACKAGE"/package.json)

  RELEASE_PLEASE_PARAMS=("${RELEASE_PLEASE_BASE_PARAMS[@]}")
  RELEASE_PLEASE_PARAMS+=("--path=$PACKAGE")
  RELEASE_PLEASE_PARAMS+=("--package-name=$packageName")
  RELEASE_PLEASE_PARAMS+=(--monorepo-tags)
  RELEASE_PLEASE_PARAMS+=(--pull-request-title-pattern="chore: release $packageName \${version}")

  debug "RUN: release-please github-release ${RELEASE_PLEASE_PARAMS[*]}"
  release-please github-release "${RELEASE_PLEASE_PARAMS[@]}" || die "release-please failed to create a GitHub release"

  debug "RUN: release-please release-pr ${RELEASE_PLEASE_PARAMS[*]}"
  release-please release-pr "${RELEASE_PLEASE_PARAMS[@]}" || die "release-please failed to create a release PR"
done

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
