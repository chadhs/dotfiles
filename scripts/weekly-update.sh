#!/bin/zsh
set -euo pipefail

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
BREWFILE="${REPO_ROOT}/Brewfile"

## preflight checks
[ -r "${BREWFILE}" ] || { echo "missing Brewfile at ${BREWFILE}, exiting..." ; exit 1; }
[ -r "${SCRIPT_DIR}/npm-pkgs.txt" ] || { echo "missing npm package list, exiting..." ; exit 1; }
[ -r "${SCRIPT_DIR}/gem-pkgs.txt" ] || { echo "missing gem package list, exiting..." ; exit 1; }

## do it!
# Single maintenance entry point. Ad-hoc: brewup / caskup / masup / npmup / gemup.
# masup (via alias) keeps the intentional double `mas outdated` + rehash workaround.
echo "updating packages..."
# shellcheck disable=SC1090
. ~/.sh_aliases \
  && update-dotfiles \
  && brewup \
  && echo "reconciling Brewfile packages..." \
  && brew bundle --file="${BREWFILE}" \
  && echo "updating Mac App Store apps..." \
  && masup \
  && echo "updating global npm packages..." \
  && npmup \
  && echo "updating global gem packages..." \
  && gemup \
  && echo "done."
