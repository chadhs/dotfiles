#!/bin/sh
# dotfiles doctor — verify this machine matches what deploy.sh sets up.
#
# Emits PASS/WARN/FAIL per check and a summary; exits non-zero when FAILs exist.
# - FAIL: broken/missing/unmanaged symlinks, missing git identity, missing tools
# - WARN: copy-once drift (baseline files are copy-once by design), missing
#   optional apps, Brewfile drift, mac-only checks skipped on other platforms
# Safe to run from anywhere; safe to re-run; changes nothing.

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${SCRIPT_DIR}/.." && pwd)"
DOTFILES="${HOME}/dotfiles"

system_type="$(uname)"

pass_count=0; warn_count=0; fail_count=0
pass(){ printf 'PASS  %s\n' "$1"; pass_count=$((pass_count+1)); }
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
# copy-once baseline files: WARN (not FAIL) when the local copy has drifted.
check_copy(){
  label="$1"; src="$2"; dst="$3"
  if [ ! -e "$dst" ]; then
    warn "${label}: missing locally (run deploy.sh)"
  elif [ ! -e "$src" ]; then
    warn "${label}: no repo baseline to compare against"
  elif diff -q "$src" "$dst" >/dev/null 2>&1; then
    pass "$label"
  else
    warn "${label}: local copy drifted from repo baseline (copy-once by design; review with: diff -u \"$src\" \"$dst\")"
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
# a global identity is ideal; per-directory identities via ~/.gitconfig-local
# includeIf -> ~/.gitconfig.d are a valid setup (commits outside those paths
# then fail loudly by design)
if command -v git >/dev/null 2>&1; then
  git_name="$(git config --global --get user.name || true)"
  git_email="$(git config --global --get user.email || true)"
  if [ -n "$git_name" ] && [ -n "$git_email" ]; then
    pass "git identity: ${git_name} <${git_email}>"
  elif ls "$HOME"/.gitconfig.d/* >/dev/null 2>&1; then
    warn "no global git identity; using per-directory identities from $HOME/.gitconfig.d (commits outside those paths will fail)"
  else
    fail "git user.name / user.email not set (add them to ~/.gitconfig-local or ~/.gitconfig.d)"
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
check_link "$HOME/.claude/skills" "$HOME/.claude/skills" "$HOME/.agents/skills"
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
  warn "mac-only checks skipped (system: ${system_type})"
fi

## summary
echo ""
printf 'doctor: %d passed, %d warnings, %d failures\n' "$pass_count" "$warn_count" "$fail_count"
if [ "$fail_count" -gt 0 ]; then
  echo "fix the failures above (usually: run deploy.sh), then re-run doctor."
  exit 1
fi
echo "all good ^_^"
