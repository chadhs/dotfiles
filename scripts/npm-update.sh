#!/bin/zsh
set -euo pipefail

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "${0}")" && pwd)"

## preflight checks
[ -r "${SCRIPT_DIR}/npm-pkgs.txt" ] || { echo "missing package list, exiting..." ; exit 1; }

## read in packages to install
npm_pkgs="$(grep '^[^#[:blank:]]' "${SCRIPT_DIR}/npm-pkgs.txt" | tr '\n' ' ')"

## do it!
# shellcheck disable=SC1090
. ~/.sh_aliases \
  && npm install -g ${=npm_pkgs}
