#!/bin/zsh
# No `set -u`: we source ~/.sh_aliases and run `cd` (update-dotfiles), which can
# trip nounset in user hooks (e.g. chruby_auto's RUBY_AUTO_VERSION) and aliases.
set -eo pipefail

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
# Source aliases first (separate statement) so brewup/masup expand. A single
# ` . aliases && brewup ` line is parsed before aliases exist, so brewup fails.
# shellcheck disable=SC1090
. ~/.sh_aliases

echo "updating packages..."
update-dotfiles
brewup
echo "reconciling Brewfile packages..."
brew bundle --file="${BREWFILE}"
echo "updating Mac App Store apps..."
masup
echo "updating global npm packages..."
npm install -g ${=npm_pkgs}
echo "updating global gem packages..."
gem install ${=gem_pkgs}
echo "done."
