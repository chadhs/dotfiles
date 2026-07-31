#!/bin/zsh
set -euo pipefail

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
BREWFILE="${REPO_ROOT}/Brewfile"

## preflight checks
[ -r "${BREWFILE}" ] || { echo "missing Brewfile at ${BREWFILE}, exiting..." ; exit 1; }

## do it!
# shellcheck disable=SC1090
. ~/.sh_aliases \
  && echo "updating brew packages..." \
  && brew update && brew doctor && brew upgrade && brew cleanup \
  && echo "reconciling Brewfile packages..." \
  && brew bundle --file="${BREWFILE}"
