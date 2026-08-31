#!/bin/sh
# omarchy post-update — health check to run after `omarchy update` and/or
# `omarchy plugin update`.
#
# Emits PASS/WARN/FAIL per check like doctor.sh; exits non-zero when FAILs
# exist. Safe to re-run.
#
# The one auto-fix: if the switcharoo plugin clone is clean (its local QML
# patches were wiped by a plugin update), re-apply the snapshot from
# omarchy/plugins/patches/switcharoo-local.patch and restart omarchy-shell.
# Everything else is report-only and needs human judgment.
#
# Checks:
#   1. switcharoo patch applied (auto-apply if missing)
#   2. switcharoo global shortcuts + sentinel binds live
#   3. switchboard service responds
#   4. hyprctl configerrors empty
#   5. shell.json drift vs omarchy's current template
#   6. doctor.sh (symlink integrity and the rest)

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${SCRIPT_DIR}/.." && pwd)"

pass_count=0; warn_count=0; fail_count=0
pass(){ printf 'PASS  %s\n' "$1"; pass_count=$((pass_count+1)); }
warn(){ printf 'WARN  %s\n' "$1"; warn_count=$((warn_count+1)); }
fail(){ printf 'FAIL  %s\n' "$1"; fail_count=$((fail_count+1)); }

SWITCHAROO_CLONE="${HOME}/.config/omarchy/plugins/io.github.gabrielvincent.switcharoo"
PATCH_FILE="${REPO_ROOT}/omarchy/plugins/patches/switcharoo-local.patch"

## 1. switcharoo patch
if [ ! -d "$SWITCHAROO_CLONE" ]; then
  fail "switcharoo clone missing: $SWITCHAROO_CLONE (omarchy plugin add gabrielvincent/omarchy-switcharoo first)"
elif [ ! -f "$PATCH_FILE" ]; then
  fail "patch snapshot missing: $PATCH_FILE"
else
  local_diff="$(git -C "$SWITCHAROO_CLONE" diff 2>/dev/null)"
  if [ -z "$local_diff" ]; then
    # Clean clone: patches absent (fresh update or fresh install). Re-apply.
    if git -C "$SWITCHAROO_CLONE" apply "$PATCH_FILE" 2>/dev/null; then
      # QML hot-reload is unreliable across plugin updates; restart the shell.
      omarchy restart shell >/dev/null 2>&1
      sleep 2
      pass "switcharoo patch re-applied to clone (shell restarted)"
    else
      fail "switcharoo patch no longer applies — upstream refactored Switcher.qml; re-port by hand (see omarchy/plugins/patches/README.md)"
    fi
  else
    if [ "$(git -C "$SWITCHAROO_CLONE" diff)" = "$(cat "$PATCH_FILE")" ]; then
      pass "switcharoo patch in place"
    else
      warn "switcharoo clone differs from snapshot — if these are intended re-ports, regenerate: git -C ~/.config/omarchy/plugins/io.github.gabrielvincent.switcharoo diff > ~/dotfiles/omarchy/plugins/patches/switcharoo-local.patch"
    fi
  fi
fi

## 2. switcharoo global shortcuts + sentinel binds
if command -v hyprctl >/dev/null 2>&1 && hyprctl -j activewindow >/dev/null 2>&1; then
  shortcuts="$(hyprctl globalshortcuts 2>/dev/null)"
  for sc in next previous; do
    case "$shortcuts" in
      *"omarchy-switcharoo:$sc"*) pass "global shortcut omarchy-switcharoo:$sc registered" ;;
      *) fail "global shortcut omarchy-switcharoo:$sc missing (plugin loaded? shell restarted?)" ;;
    esac
  done

  switcharoo_binds="$(hyprctl -j binds 2>/dev/null | jq '[.[] | select(.description == "Switcharoo switcher")] | length')"
  if [ "${switcharoo_binds:-0}" -ge 1 ]; then
    pass "switcharoo sentinel binds present ($switcharoo_binds: alt+tab family, see omarchy/hypr/bindings.lua)"
  else
    fail "no 'Switcharoo switcher' binds found (plugin checks for this sentinel; see omarchy/hypr/bindings.lua)"
  fi

  if hyprctl -j binds 2>/dev/null | jq -e '.[] | select(.description == "Switchboard: window overview")' >/dev/null 2>&1; then
    pass "switchboard binding present"
  else
    warn "switchboard binding missing (super+shift+backslash; see omarchy/hypr/bindings.lua)"
  fi

  errors="$(hyprctl configerrors 2>/dev/null)"
  if [ -z "$errors" ]; then
    pass "hyprctl configerrors clean"
  else
    fail "hyprctl configerrors: $errors"
  fi
else
  warn "hyprctl not reachable — skipping live-bind checks (run inside the Hyprland session)"
fi

## 3. switchboard service responds
if command -v omarchy-shell >/dev/null 2>&1 && omarchy-shell switchboard status 2>/dev/null | jq -e '.open != null' >/dev/null 2>&1; then
  pass "switchboard service responds"
else
  warn "switchboard service did not respond (omarchy-shell switchboard status)"
fi

## 4. template drift vs omarchy's current templates (report-only)
OMARCHY_TEMPLATES="${OMARCHY_PATH:-/usr/share/omarchy}"

template="$OMARCHY_TEMPLATES/config/omarchy/shell.json"
if [ -f "$template" ]; then
  missing_keys="$(for k in $(jq -r 'keys[]' "$template" 2>/dev/null); do
    jq -e --arg k "$k" 'has($k)' "$REPO_ROOT/omarchy/shell.json" >/dev/null 2>&1 || echo "$k"
  done)"
  if [ -n "$missing_keys" ]; then
    warn "shell.json: omarchy template has top-level keys ours lacks: $(echo $missing_keys) — review and fold in if needed ($template)"
  else
    pass "shell.json: no top-level keys missing from omarchy template"
  fi
else
  warn "omarchy shell.json template not found at $template — skipped"
fi

## 5. doctor (symlink integrity + the rest)
if sh "$SCRIPT_DIR/doctor.sh" >/dev/null 2>&1; then
  pass "doctor.sh clean"
else
  fail "doctor.sh reported FAILs — run it directly for details: sh $SCRIPT_DIR/doctor.sh"
fi

echo "omarchy-post-update: $pass_count passed, $warn_count warnings, $fail_count failures"
[ "$fail_count" -eq 0 ] || exit 1
