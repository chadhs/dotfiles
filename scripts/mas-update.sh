#!/bin/zsh
set -euo pipefail

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "${0}")" && pwd)"

## preflight checks
[ -r "${SCRIPT_DIR}/mas-pkgs.txt" ] || { echo "missing package list, exiting..." ; exit 1; }

## read in packages to install
mas_pkgs="$(grep '^[^#[:blank:]]' "${SCRIPT_DIR}/mas-pkgs.txt" | tr '\n' ' ')"

## do it!
# Prefer Brewfile + `brew bundle` for new setups; this script remains for mas-only refreshes.
# shellcheck disable=SC1090
. ~/.sh_aliases \
  && echo "updating mac app store apps..." \
  # Refresh mas's outdated cache twice + rehash so upgrade does not
  # retry apps that were already updated (historical mas quirk).
  && mas outdated && mas outdated && rehash && mas upgrade \
  && echo "installing missing mac app store apps..." \
  && mas outdated && mas install ${=mas_pkgs}
