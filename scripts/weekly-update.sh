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

## read in language package lists
npm_pkgs="$(grep '^[^#[:blank:]]' "${SCRIPT_DIR}/npm-pkgs.txt" | tr '\n' ' ')"
gem_pkgs="$(grep '^[^#[:blank:]]' "${SCRIPT_DIR}/gem-pkgs.txt" | tr '\n' ' ')"

## do it!
echo "updating packages..."
# shellcheck disable=SC1090
. ~/.sh_aliases \
  && update-dotfiles \
  && brew update && brew doctor && brew upgrade && brew cleanup \
  && echo "reconciling Brewfile packages..." \
  && brew bundle --file="${BREWFILE}" \
  && echo "updating Mac App Store apps..." \
  # Refresh mas's outdated cache twice + rehash so upgrade does not
  # retry apps that were already updated (historical mas quirk).
  && mas outdated && mas outdated && rehash && mas upgrade \
  && echo "updating global npm packages..." \
  && npm install -g ${=npm_pkgs} \
  && echo "updating global gem packages..." \
  && gem install ${=gem_pkgs} \
  && echo "done."
