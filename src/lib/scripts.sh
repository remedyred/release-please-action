#!/bin/bash

# Check if npm script exists
#:: hasScript <script_name>
hasScript() {
  local script_name="$1"
  jq ".scripts | has(\"$script_name\")" package.json
}
export -f hasScript

PACKAGES="$(pnpm ls -r --depth -1 --parseable)"
export PACKAGES

# Run npm script
#:: run_script <script_name>
runScript() {
  local script_name="$1"
  local PNPM_RUN_COMMAND="pnpm run --if-present"

  if hasScript "$script_name"; then
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
