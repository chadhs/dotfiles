#!/bin/sh
# dotfiles doctor — verify this machine matches what deploy.sh sets up.
#
# Emits PASS/INFO/WARN/FAIL per check and a summary; exits non-zero when FAILs exist.
# - FAIL: broken/missing/unmanaged symlinks, unresolved git identity, missing tools
# - WARN: should be looked at eventually (missing optional apps, Brewfile drift,
#   drifted login shell, missing ssh keys, unreachable session checks)
# - INFO: expected state, nothing to act on (copy-once baseline drift, another
#   OS's checks skipped)
# Safe to run from anywhere; safe to re-run; changes nothing.

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${SCRIPT_DIR}/.." && pwd)"
DOTFILES="${HOME}/dotfiles"

system_type="$(uname)"

pass_count=0; info_count=0; warn_count=0; fail_count=0
pass(){ printf 'PASS  %s\n' "$1"; pass_count=$((pass_count+1)); }
info(){ printf 'INFO  %s\n' "$1"; info_count=$((info_count+1)); }
warn(){ printf 'WARN  %s\n' "$1"; warn_count=$((warn_count+1)); }
fail(){ printf 'FAIL  %s\n' "$1"; fail_count=$((fail_count+1)); }

# check_link <label> <path> <expected-target>
# PASS if path is a live symlink resolving under expected-target.
check_link(){
  label="$1"; path="$2"; want="$3"
  if [ -L "$path" ]; then
    if [ ! -e "$path" ]; then
      fail "${label}: dangling symlink -> $(readlink "$path")"
    else
      target="$(readlink "$path")"
      case "$target" in
        "$want"|"$want"/*) pass "$label" ;;
        *) fail "${label}: symlink -> ${target} (expected ${want})" ;;
      esac
    fi
  elif [ -e "$path" ]; then
    fail "${label}: exists but is not a symlink (local override removed the repo link)"
  else
    fail "${label}: missing (run deploy.sh)"
  fi
}

# check_copy <label> <repo-baseline> <local-copy>
# copy-once baseline files: local edits are expected to win over time, so
# drift is INFO (expected state) — only a missing local copy is actionable.
check_copy(){
  label="$1"; src="$2"; dst="$3"
  if [ ! -e "$dst" ]; then
    warn "${label}: missing locally (run deploy.sh)"
  elif [ ! -e "$src" ]; then
    warn "${label}: no repo baseline to compare against"
  elif diff -q "$src" "$dst" >/dev/null 2>&1; then
    pass "$label"
  else
    info "${label}: local copy drifted from repo baseline (copy-once by design; review with: diff -u \"$src\" \"$dst\")"
  fi
}

## repo present?
if [ ! -d "${DOTFILES}/.git" ]; then
  fail "dotfiles repo not found at ${DOTFILES} (deploy.sh manages links from there)"
fi
if [ "${REPO_ROOT}" != "${DOTFILES}" ]; then
  warn "doctor.sh running from ${REPO_ROOT} but deploy.sh manages links from ${DOTFILES}"
fi

## git identity (gitconfig sets useconfigonly)
# What matters is that an identity resolves where commits actually happen.
# A global user.* counts, and so does the includeIf gitdir setup
# (~/.gitconfig-local -> ~/.gitconfig.d), so probe the dotfiles repo itself
# rather than only the traditional global config (which also misses the XDG
# ~/.config/git/config path).
if command -v git >/dev/null 2>&1; then
  if git -C "$DOTFILES" config user.name >/dev/null 2>&1 &&
     git -C "$DOTFILES" config user.email >/dev/null 2>&1; then
    pass "git identity resolves in $DOTFILES ($(git -C "$DOTFILES" config user.email))"
  else
    fail "git user.name / user.email do not resolve in $DOTFILES (set them globally in ~/.config/git/config or ~/.gitconfig-local, or add includeIf gitdir blocks covering the path)"
  fi
else
  fail "git not installed"
fi

## manifest-driven link/copy checks — same source of truth as deploy.sh.
## Only bespoke checks live below; add new links via scripts/links.conf.
manifest="${DOTFILES}/scripts/links.conf"
if [ -r "${manifest}" ]; then
  while IFS='|' read -r mode scope target src; do
    case "${mode}" in ''|\#*) continue ;; esac
    if [ "${scope}" = "mac" ] && [ "${system_type}" != "Darwin" ]; then
      continue
    fi
    if [ "${scope}" = "linux" ] && [ "${system_type}" != "Linux" ]; then
      continue
    fi
    case "${target}" in
      /*) t="${target}" ;;
      *) t="${HOME}/${target}" ;;
    esac
    s="${DOTFILES}/${src}"
    case "${mode}" in
      link|force|forcelink) check_link "${target}" "${t}" "${s}" ;;
      copy)                 check_copy "${target}" "${s}" "${t}" ;;
      *) warn "links.conf: unknown mode '${mode}' (target ${target})" ;;
    esac
  done < "${manifest}"
else
  fail "link manifest missing: ${manifest} (deploy.sh and doctor.sh share it)"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
  pass "oh-my-zsh installed"
else
  fail "oh-my-zsh missing (zshrc sources it unconditionally; run deploy.sh)"
fi

## git hooks
hooks_path="$(git config --global --get core.hooksPath || true)"
# gitconfig stores the literal tilde form; git expands it at use time
# shellcheck disable=SC2086,SC2088  # literal tilde comparison is intentional
if [ "$hooks_path" = "$HOME/.config/git/hooks" ] || [ "$hooks_path" = "~/.config/git/hooks" ]; then
  pass "core.hooksPath points at $HOME/.config/git/hooks"
else
  warn "core.hooksPath is '${hooks_path:-unset}' (expected ~/.config/git/hooks)"
fi

## agent skills
# ~/.claude/skills layout is platform-dependent:
# - real dir: omarchy owns it (per-skill links into /usr/share/omarchy/...);
#   deploy.sh merges our skills into it per-skill alongside omarchy's. If a
#   name is held by an omarchy-managed skill, ours is shadowed — WARN.
# - symlink: plain platforms — must point at the ~/.agents/skills merge dir.
if [ -d "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
  for skill in "$DOTFILES"/utils/agents/skills/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    if [ -e "$HOME/.claude/skills/$name" ] && [ ! -L "$HOME/.claude/skills/$name" ]; then
      warn "claude skill ${name}: shadowed by a real dir in .claude/skills"
    elif [ -L "$HOME/.claude/skills/$name" ] && [ "$(readlink "$HOME/.claude/skills/$name")" != "$skill" ]; then
      warn "claude skill ${name}: shadowed by an omarchy-managed (or foreign) skill"
    else
      check_link "claude skill ${name}" "$HOME/.claude/skills/$name" "$skill"
    fi
  done
else
  check_link ".claude/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"
fi
if [ -d "$HOME/.agents/skills" ]; then
  for skill in "$DOTFILES"/utils/agents/skills/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    check_link "skill ${name}" "$HOME/.agents/skills/$name" "$skill"
  done
else
  fail "$HOME/.agents/skills merge dir missing (run deploy.sh)"
fi

## mac-only checks
if [ "$system_type" = "Darwin" ]; then
  ## iCloud Drive link (only meaningful when iCloud is signed in)
  if [ -d "$HOME/Library/Mobile Documents/com~apple~CloudDocs" ]; then
    check_link "$HOME/iCloudDrive" "$HOME/iCloudDrive" "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
  fi

  ## virtualenvwrapper hooks (bootstrap symlinks these when ~/.virtualenvs exists)
  if [ -d "$HOME/.virtualenvs" ]; then
    check_link "virtualenvs postactivate"   "$HOME/.virtualenvs/postactivate"   "$DOTFILES/utils/virtualenvwrapper-zsh-hooks/postactivate"
    check_link "virtualenvs postdeactivate" "$HOME/.virtualenvs/postdeactivate" "$DOTFILES/utils/virtualenvwrapper-zsh-hooks/postdeactivate"
  fi

  ## toolchain
  if command -v brew >/dev/null 2>&1; then
    pass "Homebrew on PATH"
    brew_prefix="$(brew --prefix 2>/dev/null)"
    # read the authoritative login shell from Directory Services, not $SHELL
    # ($SHELL reflects the launching session, which may predate a chsh)
    login_shell="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
    if [ "$login_shell" = "${brew_prefix}/bin/zsh" ]; then
      pass "login shell is Homebrew zsh"
    else
      warn "login shell is ${login_shell:-unknown} (expected ${brew_prefix}/bin/zsh; run bootstrap-mac.sh or: chsh -s ${brew_prefix}/bin/zsh)"
    fi
    if xcode-select -p >/dev/null 2>&1; then
      pass "Xcode Command Line Tools present"
    else
      fail "Xcode Command Line Tools missing (xcode-select --install)"
    fi
    if bundle_out="$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file="${DOTFILES}/Brewfile" 2>&1)"; then
      pass "Brewfile packages all installed"
    else
      warn "Brewfile drift:"
      printf '%s\n' "$bundle_out" | sed 's/^/      /'
    fi
  else
    fail "Homebrew not on PATH (run scripts/bootstrap-mac.sh)"
  fi

  ## cask apps that deploy.sh-linked configs depend on
  for app in "Ghostty" "Emacs" "espanso" "Karabiner-Elements"; do
    if [ -d "/Applications/${app}.app" ]; then
      pass "app: ${app}"
    else
      warn "app missing: /Applications/${app}.app (brew bundle install or: brew install --cask)"
    fi
  done

  ## mas / App Store sign-in (best effort; mas 2.x removed the `account` subcommand)
  if command -v mas >/dev/null 2>&1; then
    if mas outdated >/dev/null 2>&1; then
      pass "mas can reach the App Store"
    else
      warn "mas couldn't query the App Store (sign in to the App Store app)"
    fi
  else
    warn "mas not installed (in the Brewfile; run brew bundle)"
  fi

  ## ssh identities: either declared in config.d or loaded into ssh-agent
  if grep -rq "IdentityFile\|IdentityAgent" "$HOME/.ssh/config.d/" 2>/dev/null; then
    pass "ssh identity configured in config.d"
  elif ssh-add -l >/dev/null 2>&1; then
    pass "ssh identities loaded in ssh-agent ($(ssh-add -l | wc -l | tr -d ' ') key(s))"
  else
    warn "no IdentityFile/IdentityAgent in $HOME/.ssh/config.d/ and no keys in ssh-agent"
  fi
else
  info "mac-only checks skipped (system: ${system_type})"
fi

## linux (omarchy/arch) checks
if [ "$system_type" = "Linux" ]; then
  if command -v zsh >/dev/null 2>&1; then
    pass "zsh installed"
  else
    fail "zsh not installed (run deploy.sh or: sudo pacman -S zsh)"
  fi

  # git-host auth toolchain: direnv loads per-project gh tokens from .envrc;
  # editorconfig-core-c is the one repo package omarchy-base doesn't carry
  for tool in direnv gh glab editorconfig; do
    if command -v "$tool" >/dev/null 2>&1; then
      pass "tool: ${tool}"
    else
      fail "tool missing: ${tool} (run deploy.sh or: sudo pacman -S)"
    fi
  done

  # per-account git auth relies on keys in ~/.ssh (provisioned manually,
  # machine-local — never in the repo). The keys that matter are the ones the
  # per-identity ~/.gitconfig.d sshCommand entries point at (e.g.
  # chadhs-omtower); a conventional id_* private key is the fallback. No
  # `ls glob1 glob2` tricks: one unmatched glob makes ls exit non-zero even
  # when other matches exist (the old check false-alarmed on ed25519-only
  # setups).
  referenced_keys="$(grep -h -o 'ssh -i [^"]*' "$HOME"/.gitconfig.d/* 2>/dev/null | sed 's|^ssh -i ||' | sort -u)"
  if [ -n "$referenced_keys" ]; then
    missing_keys=""
    # shellcheck disable=SC2086  # one path per line, no spaces expected
    for key in $referenced_keys; do
      case "$key" in
        \~*) key="$HOME${key#\~}" ;;
      esac
      [ -f "$key" ] || missing_keys="$missing_keys $key"
    done
    if [ -z "$missing_keys" ]; then
      pass "ssh keys referenced by gitconfig.d present in ~/.ssh"
    else
      fail "gitconfig.d references missing ssh keys:$missing_keys (copy the per-account keys to ~/.ssh)"
    fi
  elif [ -n "$(find "$HOME/.ssh" -maxdepth 1 -type f -name 'id_*' ! -name '*.pub' 2>/dev/null)" ]; then
    pass "ssh keys present in ~/.ssh (id_* convention)"
  else
    warn "no ssh keys in ~/.ssh and none referenced by gitconfig.d (copy per-account keys manually)"
  fi

  # authoritative login shell from passwd, not $SHELL (may predate a chsh)
  login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  if [ "$login_shell" = "/usr/bin/zsh" ]; then
    pass "login shell is /usr/bin/zsh"
  else
    warn "login shell is ${login_shell:-unknown} (expected /usr/bin/zsh; run deploy.sh or: chsh -s /usr/bin/zsh)"
  fi

  # omarchy env bootstrap should be present for the shared profile to source
  if [ -r /usr/share/omarchy/default/bash/env-bootstrap ]; then
    pass "omarchy env-bootstrap present"
  else
    warn "/usr/share/omarchy/default/bash/env-bootstrap missing (is this an omarchy install? profile's linux branch sources it)"
  fi

  # AUR packages from omarchy/aur.packages (deploy.sh installs them).
  aur_list="${DOTFILES}/scripts/list-aur-packages.sh"
  if [ -x "$aur_list" ]; then
    while IFS= read -r pkg || [ -n "$pkg" ]; do
      [ -n "$pkg" ] || continue
      if pacman -Q "$pkg" >/dev/null 2>&1; then
        pass "aur: ${pkg}"
      else
        fail "aur package missing: ${pkg} (run deploy.sh)"
      fi
    done <<EOF
$("$aur_list")
EOF
  else
    fail "scripts/list-aur-packages.sh missing (cannot check omarchy/aur.packages)"
  fi

  # mise CLIs deploy.sh pins when mise is present (same trio as
  # omarchy-agent-tools-update).
  for tool in claude codex opencode; do
    if command -v "$tool" >/dev/null 2>&1; then
      pass "tool: ${tool}"
    else
      fail "tool missing: ${tool} (run deploy.sh — mise use -g ${tool}@latest)"
    fi
  done

  # Packaged Vicinae unit: deploy.sh enables it once vicinae-bin is installed.
  if pacman -Q vicinae-bin >/dev/null 2>&1; then
    if systemctl --user is-enabled vicinae.service >/dev/null 2>&1; then
      pass "vicinae.service enabled"
    else
      fail "vicinae.service not enabled (run deploy.sh or: systemctl --user enable --now vicinae.service)"
    fi
    # Copy-once can leave an empty live file if Vicinae created it first.
    repo_sc="${DOTFILES}/omarchy/vicinae/shortcuts.json"
    live_sc="${HOME}/.local/share/vicinae/shortcuts/shortcuts.json"
    if [ -f "$repo_sc" ] && [ -f "$live_sc" ] && command -v python3 >/dev/null 2>&1; then
      missing="$(python3 - "$repo_sc" "$live_sc" <<'PY'
import json, sys
repo, live = sys.argv[1], sys.argv[2]
try:
    with open(repo, encoding="utf-8") as f:
        want = [s["id"] for s in json.load(f) if isinstance(s, dict) and s.get("id")]
    with open(live, encoding="utf-8") as f:
        data = json.load(f)
    have = {s.get("id") for s in data if isinstance(s, dict)} if isinstance(data, list) else set()
except (OSError, json.JSONDecodeError, TypeError):
    print("unreadable")
    raise SystemExit(0)
print(" ".join(i for i in want if i not in have))
PY
)"
      if [ -n "$missing" ]; then
        fail "vicinae shortcuts missing: ${missing} (run deploy.sh — it seeds missing ids)"
      else
        pass "vicinae shortcuts present"
      fi
    fi
  fi

  # No chord may carry two handlers (omarchy default + repo rebind both firing,
  # e.g. SUPER+ALT+Arrows was both move-into-group and a Moom nudge). The
  # release flag is part of the chord: push-to-talk legitimately binds start
  # on press and stop on release of the same key. Binds that report an empty
  # key (omarchy's lua-layer workspace binds on this Hyprland) can't be
  # checked here.
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && hyprctl -j binds >/dev/null 2>&1; then
    dupes="$(hyprctl -j binds 2>/dev/null | jq -r '
      [ .[] | select(.key != "")
        | "\(.submap):\(.modmask):\(.release):\(.key)" ]
      | group_by(.) | map(select(length > 1) | .[0]) | .[]')"
    if [ -n "$dupes" ]; then
      fail "duplicate chord binds in hyprland (multiple handlers fire): $(echo "$dupes" | tr '\n' ' ')"
    else
      pass "no duplicate chord binds"
    fi
  else
    info "hyprctl/jq not reachable — skipping duplicate-chord check"
  fi
else
  info "linux-only checks skipped (system: ${system_type})"
fi

## summary
echo ""
printf 'doctor: %d passed, %d info, %d warnings, %d failures\n' "$pass_count" "$info_count" "$warn_count" "$fail_count"
if [ "$fail_count" -gt 0 ]; then
  echo "fix the failures above (usually: run deploy.sh), then re-run doctor."
  exit 1
fi
echo "all good ^_^"
