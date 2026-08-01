#!/bin/sh
# Open files in Neovim inside Ghostty (Finder "Open With" helper).
# Used by utils/Open in Neovim.app

set -eu

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <file> [file...]" >&2
  exit 1
fi

NVIM="$(command -v nvim || true)"
[ -n "${NVIM}" ] || NVIM="/opt/homebrew/bin/nvim"
[ -x "${NVIM}" ] || NVIM="/usr/local/bin/nvim"
[ -x "${NVIM}" ] || {
  osascript -e 'display alert "Neovim not found" message "Install nvim (brew install nvim) and ensure it is on PATH."'
  exit 1
}

GHOSTTY="/Applications/Ghostty.app"
[ -d "${GHOSTTY}" ] || {
  osascript -e 'display alert "Ghostty not found" message "Install Ghostty (brew install --cask ghostty)." as critical'
  exit 1
}

# Open each file in its own Ghostty + nvim window
for file in "$@"; do
  abs="$(cd "$(dirname "${file}")" && pwd)/$(basename "${file}")"
  open -na "${GHOSTTY}" --args -e "${NVIM}" "${abs}"
done
