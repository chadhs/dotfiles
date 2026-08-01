#!/bin/zsh
set -euo pipefail

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
BREWFILE="${REPO_ROOT}/Brewfile"

## preflight checks
[ -r "${BREWFILE}" ] || { echo "missing Brewfile at ${BREWFILE}, exiting..." ; exit 1; }

## do it!
# `mas outdated && mas outdated && rehash && mas upgrade` is intentional: refreshing the
# outdated list twice and rehashing avoids mas retrying apps that were already upgraded
# (historical mas quirk). Missing App Store apps are reconciled via Brewfile.
# shellcheck disable=SC1090
. ~/.sh_aliases \
  && echo "updating mac app store apps..." \
  && mas outdated && mas outdated && rehash && mas upgrade \
  && echo "reconciling Brewfile mas packages..." \
  && brew bundle --file="${BREWFILE}"
