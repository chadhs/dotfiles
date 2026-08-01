#!/bin/sh
# Open files in Neovim inside Ghostty (Finder "Open With" helper).
# Used by utils/Open in Neovim.app
#
# Important: do NOT pass the target file as a Ghostty argv after -e.
# Ghostty treats extra path args as files to open/run (permission prompts,
# extra tabs). Use a short-lived wrapper script instead.

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

wrap_dir="${TMPDIR:-/tmp}/open-in-neovim"
mkdir -p "${wrap_dir}"

# Open each file in its own Ghostty + nvim window
for file in "$@"; do
  abs="$(cd "$(dirname "${file}")" && pwd)/$(basename "${file}")"
  wrapper="$(mktemp "${wrap_dir}/wrap.XXXXXX")"
  # Embed paths with %q so spaces/quotes are safe; wrapper is the only -e arg.
  cat > "${wrapper}" <<EOF
#!/bin/sh
exec $(printf %q "${NVIM}") $(printf %q "${abs}")
EOF
  chmod +x "${wrapper}"
  open -na "${GHOSTTY}" --args -e "${wrapper}"
  # Ghostty reads the wrapper at start; remove shortly after.
  (sleep 15; rm -f "${wrapper}") &
done
