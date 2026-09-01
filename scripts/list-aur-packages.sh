#!/bin/sh
# Print AUR package names from omarchy/aur.packages, one per line.
# Skips blanks and comments (# to end of line). Safe to run from any cwd.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${HOME}/dotfiles/omarchy/aur.packages"
[ -r "${MANIFEST}" ] || MANIFEST="${REPO_ROOT}/omarchy/aur.packages"

if [ ! -r "${MANIFEST}" ]; then
  echo "list-aur-packages: missing ${MANIFEST}" >&2
  exit 1
fi

while IFS= read -r line || [ -n "${line}" ]; do
  line="${line%%#*}"
  line="$(printf '%s' "${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -n "${line}" ] || continue
  printf '%s\n' "${line}"
done < "${MANIFEST}"
