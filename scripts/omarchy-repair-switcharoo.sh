#!/bin/sh
# Explicit repair, kept separate from the read-only post-update audit.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
clone="$HOME/.config/omarchy/plugins/io.github.gabrielvincent.switcharoo"
patch="$root/omarchy/plugins/patches/switcharoo-local.patch"
[ -z "$(git -C "$clone" status --porcelain)" ] || {
  echo "Plugin has local changes; preserve them and review manually." >&2
  exit 1
}
git -C "$clone" apply --check "$patch"
git -C "$clone" apply "$patch"
omarchy restart shell
echo "Switcharoo patch applied; shell restarted. Run the post-update audit next."
