#!/bin/bash
# shellcheck disable=SC2155

export CYAN='\033[0;36m'
export YELLOW='\033[0;33m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export GREY='\033[0;37m'
export GRAY="$GREY"
export NC='\033[0m'

term_width="$(tput cols 2>/dev/null || echo 140)"
padding="$(printf '%0.1s' ={1..500})"
title() {
  printf ' %*.*s %s %*.*s\n' 0 "$(((term_width - 3 - ${#1}) / 2))" "$padding" "$1" 0 "$(((term_width - 2 - ${#1}) / 2))" "$padding"
}
export -f title

debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "${YELLOW}[DEBUG]${NC} $1"
  fi
}
export -f debug

info() {
  echo -e "${CYAN}[INFO]${NC} $1"
}
export -f info

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}
export -f warn

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}
export -f error

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}
export -f success

log() {
  echo -e "${GREY}[LOG]${NC} $1"
}
export -f log

die() {
  error "$1"
  exit 1
}
export -f die

finish() {
  local MESSAGE=${1:-"Finished!"}
  success "$MESSAGE"
  exit 0
}
export -f finish

line() {
  local style=${1:-" "}
  shift
  local line
  line=$(printf "%${term_width}s" " ")
  echo -e "${line// /${style}}"
}
export -f line
