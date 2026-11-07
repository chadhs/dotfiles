#!/bin/sh
# Remove only the old dotfiles-owned usage integrations replaced by Omarchy 4.5.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
stock=${OMARCHY_PATH:-/usr/share/omarchy}
for collector in codex cursor opencode; do
  [ -x "$stock/bin/omarchy-agent-usage-$collector" ] || {
    echo "Stock $collector collector missing; leaving old usage integration untouched" >&2
    exit 1
  }
done

for unit in omarchy-cursor-record.path omarchy-cursor-record.timer omarchy-cursor-record.service \
            omarchy-opencode-go-record.path omarchy-opencode-go-record.timer omarchy-opencode-go-record.service \
            omarchy-codex-record.path omarchy-codex-record.service; do
  link="$HOME/.config/systemd/user/$unit"
  target=$(readlink "$link" 2>/dev/null || true)
  [ "$target" = "$root/omarchy/systemd/user/$unit" ] || continue
  if systemctl --user is-active --quiet "$unit"; then
    systemctl --user stop "$unit"
  fi
  # A checkout may already have deleted the old unit's source. Remove only
  # our enablement links even when systemctl can no longer load that unit.
  for enabled in "$HOME"/.config/systemd/user/*.wants/"$unit" \
                 "$HOME"/.config/systemd/user/*.requires/"$unit"; do
    [ -L "$enabled" ] || continue
    [ "$(readlink -m "$enabled")" != "$root/omarchy/systemd/user/$unit" ] || rm "$enabled"
  done
  [ ! -L "$link" ] || rm "$link"
done

for name in omarchy-agent-usage-cursor omarchy-cursor-record \
            omarchy-agent-usage-opencode-go omarchy-opencode-go-record \
            omarchy-codex-limit-probe omarchy-codex-limit-patch; do
  link="$HOME/.local/bin/$name"
  target=$(readlink "$link" 2>/dev/null || true)
  [ "$target" != "$root/omarchy/bin/$name" ] || rm "$link"
done
systemctl --user daemon-reload

# The Go record is now named opencode. Keep history outside the panel's watch directory.
usage="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/agents/usage"
if [ -f "$usage/opencode-go.json" ]; then
  archive="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/backups/retired-usage"
  mkdir -p "$archive"
  chmod 700 "$archive"
  mv "$usage/opencode-go.json" "$archive/opencode-go.$(date +%s).json"
fi
