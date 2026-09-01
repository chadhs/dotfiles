#!/bin/sh
# dotfiles deploy

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${SCRIPT_DIR}/.." && pwd)"
# deploy manages links from ~/dotfiles (matches doctor.sh and bootstrap);
# fall back to the in-place repo when running from a checkout elsewhere
DOTFILES_ROOT="${HOME}/dotfiles"
[ -d "${DOTFILES_ROOT}" ] || DOTFILES_ROOT="${REPO_ROOT}"


## helpers
update_repo(){
  cd ~/dotfiles || exit 1
  git pull -q || echo "offline — skipping repo update"
}

os_setup(){
  system_type="$(uname)"
  if [ "$system_type" = "Darwin" ]; then
    system_os="macos"
    pkg_install="brew install"
    package_list="editorconfig git nvim tmux zsh"
    cask_package_list="emacs-app"
  elif [ "$system_type" = "FreeBSD" ]; then
    system_os="freebsd"
    pkg_install="sudo pkg install -y"
    package_list="editorconfig-core-c emacs-nox11 git tmux vim-console zsh"
  elif [ "$system_type" = "Linux" ]; then
    if grep -qi "arch" /etc/os-release 2>/dev/null || command -v pacman >/dev/null 2>&1; then
      system_os="arch"
      pkg_install="sudo pacman -S --needed"
      # git, tmux, zsh etc. ship with omarchy (omarchy-base.packages is the
      # real base manifest — verified there); this list is only the repo's
      # delta plus the git-host auth toolchain (direnv loads per-project
      # gh tokens)
      package_list="editorconfig-core-c zsh direnv github-cli glab"
    elif grep -qi "ubuntu\|debian" /proc/version; then
      system_os="debian"
      pkg_install="sudo apt-get install -y"
      package_list="editorconfig  emacs-nox git tmux vim-nox zsh"
    elif grep -qi "red hat" /proc/version; then
      ### enable epel repo to have access to expanded package library
      sudo yum install -y epel-release
      system_os="redhat"
      pkg_install="sudo yum install -y"
      package_list="emacs-nox git tmux vim-enhanced zsh"
    fi
  fi
  echo "setting up your dotfiles and default packages for a $system_os system..."
  echo ""
}

verify_packages(){
  # intentional word splitting: pkg_install and package_list are space-separated lists
  # shellcheck disable=SC2086
  $pkg_install $package_list
  if [ "$system_os" = "macos" ]; then
    # intentional word splitting: cask_package_list is a space-separated list
    # shellcheck disable=SC2086
    brew install --cask $cask_package_list
  fi
  if [ "$system_os" = "arch" ]; then
    aur_list="${DOTFILES_ROOT}/scripts/list-aur-packages.sh"
    if [ -x "$aur_list" ]; then
      aur_pkgs=""
      while IFS= read -r pkg || [ -n "$pkg" ]; do
        [ -n "$pkg" ] || continue
        aur_pkgs="$aur_pkgs $pkg"
      done <<EOF
$("$aur_list")
EOF
      if [ -n "$aur_pkgs" ]; then
        echo "installing AUR packages from omarchy/aur.packages..."
        # shellcheck disable=SC2086
        omarchy pkg aur add $aur_pkgs
      fi
    fi
    if command -v mise >/dev/null 2>&1; then
      echo "pinning mise CLIs: claude, codex, opencode..."
      mise use -g claude@latest codex@latest opencode@latest
    fi
  fi
}

# Symlink each skill directory from src into dest. Skip missing globs and hidden names.
link_skills_from(){
  src="$1"
  dest="$2"
  for skill in "$src"/*; do
    [ -e "$skill" ] || continue
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    case "$name" in
      .*) continue ;;
    esac
    ln -sfn "$skill" "$dest/$name"
  done
}

# Merge repo + machine-local skill dirs into ~/.agents/skills as per-skill symlinks.
# Local names override shared names. ~/.claude/skills layout is platform-dependent:
# - real dir (omarchy owns it, per-skill links into /usr/share/omarchy/...):
#   merge our skills into it per-skill alongside omarchy's, never clobbering
#   package-managed names
# - symlink or missing: point it at the merge dir (mac and plain linux)
link_agent_skills(){
  shared="$HOME/dotfiles/utils/agents/skills"
  local_dir="$HOME/.agents/skills-local"
  dest="$HOME/.agents/skills"

  mkdir -p "$shared" "$local_dir" "$dest" "$HOME/.claude"

  if [ -L "$dest" ]; then
    rm -f "$dest"
    mkdir -p "$dest"
  fi

  link_skills_from "$shared" "$dest"
  link_skills_from "$local_dir" "$dest"

  for entry in "$dest"/*; do
    [ -L "$entry" ] || continue
    name="$(basename "$entry")"
    case "$name" in
      .*) continue ;;
    esac
    if [ -d "$shared/$name" ] || [ -d "$local_dir/$name" ]; then
      continue
    fi
    rm -f "$entry"
  done

  if [ -d "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
    # omarchy-managed real dir: add our skills per-skill, leave package-managed
    # names (e.g. omarchy's own skills) untouched. Only links pointing into our
    # dotfiles trees are ours to manage.
    for entry in "$dest"/*; do
      [ -L "$entry" ] || continue
      name="$(basename "$entry")"
      case "$name" in
        .*) continue ;;
      esac
      target="$HOME/.claude/skills/$name"
      source="$(readlink -f "$entry")"
      if [ -L "$target" ]; then
        case "$(readlink "$target")" in
          "$HOME/dotfiles/"*|"$HOME/.agents/"*) ln -sfn "$source" "$target" ;;
          # omarchy-managed or foreign: leave alone
        esac
      elif [ ! -e "$target" ]; then
        ln -s "$source" "$target"
      fi
    done
    # Prune our stale links (skill removed or renamed upstream of the merge dir).
    for target in "$HOME/.claude/skills"/*; do
      [ -L "$target" ] || continue
      name="$(basename "$target")"
      [ -e "$dest/$name" ] && continue
      case "$(readlink "$target")" in
        "$HOME/dotfiles/"*|"$HOME/.agents/"*) rm -f "$target" ;;
      esac
    done
  elif [ -L "$HOME/.claude/skills" ] || [ ! -e "$HOME/.claude/skills" ]; then
    ln -sfn "$dest" "$HOME/.claude/skills"
  fi
}

# On arch, omarchy ships stock user configs at several repo-managed paths
# (editor configs, the vendored omarchy files, bin scripts). Guarded link
# modes skip existing targets, and force replaces real files outright — so
# before linking, move any real (non-symlink) target aside exactly once.
# Driven by the manifest (non-mac-scoped link|force entries) so future links
# inherit backup behavior automatically; machine-local .bak-omarchy copies
# are never committed. Symlinks are left for doctor.sh to flag.
backup_omarchy_configs(){
  [ "$system_os" = "arch" ] || return 0
  manifest="${DOTFILES_ROOT}/scripts/links.conf"
  [ -r "${manifest}" ] || return 0
  while IFS='|' read -r mode scope target src; do
    case "${mode}" in ''|\#*) continue ;; esac
    [ "${scope}" = "mac" ] && continue
    case "${mode}" in
      link|force) ;;
      *) continue ;;
    esac
    case "${target}" in
      /*) t="${target}" ;;
      *) t="${HOME}/${target}" ;;
    esac
    [ -e "${t}" ] || continue
    [ -L "${t}" ] && continue
    backup="${t}.bak-omarchy"
    [ -e "${backup}" ] && backup="${backup}-$(date +%Y%m%d%H%M%S)"
    mv "${t}" "${backup}" && echo "backed up ${t} -> ${backup}"
  done < "${manifest}"

  ## supplemental: omarchy's XDG emacs dir is not a manifest target (the repo
  ## links ~/.emacs and ~/.emacs.d/*), but it must move aside so emacs
  ## unambiguously reads the repo's init chain
  t="${HOME}/.config/emacs"
  if [ -e "${t}" ] && [ ! -L "${t}" ]; then
    backup="${t}.bak-omarchy"
    [ -e "${backup}" ] && backup="${backup}-$(date +%Y%m%d%H%M%S)"
    mv "${t}" "${backup}" && echo "backed up ${t} -> ${backup}"
  fi
}

# On arch/omarchy the login shell should be /usr/bin/zsh so the repo's zsh
# chain is what sessions get; offer the chsh rather than doing it silently.
offer_login_shell_change(){
  [ "$system_os" = "arch" ] || return 0
  login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  [ "$login_shell" = "/usr/bin/zsh" ] && return 0
  printf 'login shell is %s — change it to /usr/bin/zsh? [y/N] ' "${login_shell:-unknown}"
  read -r reply
  case "$reply" in
    y|Y|yes)
      sudo chsh -s /usr/bin/zsh "$(id -un)" && echo "login shell changed to /usr/bin/zsh (re-login to use it)"
      ;;
    *)
      echo "keeping ${login_shell}; run: chsh -s /usr/bin/zsh"
      ;;
  esac
}

# Apply links/copies from scripts/links.conf — the single source of truth
# shared with scripts/doctor.sh. Add new links there, not here; only bespoke
# logic lives in symlink_configs below.
apply_links(){
  manifest="${DOTFILES_ROOT}/scripts/links.conf"
  [ -r "${manifest}" ] || { echo "missing link manifest at ${manifest}, exiting..." ; exit 1; }
  while IFS='|' read -r mode scope target src; do
    case "${mode}" in ''|\#*) continue ;; esac
    if [ "${scope}" = "mac" ] && [ "${system_os}" != "macos" ]; then
      continue
    fi
    if [ "${scope}" = "linux" ]; then
      case "${system_os}" in
        arch|debian|redhat) ;;
        *) continue ;;
      esac
    fi
    case "${target}" in
      /*) t="${target}" ;;
      *) t="${HOME}/${target}" ;;
    esac
    s="${DOTFILES_ROOT}/${src}"
    mkdir -p "$(dirname "${t}")"
    case "${mode}" in
      link)
        [ ! -e "${t}" ] && ln -s "${s}" "${t}"
        ;;
      force)
        if [ -d "${t}" ] && [ ! -L "${t}" ]; then
          rm -rf "${t}"
        fi
        ln -sfn "${s}" "${t}"
        ;;
      forcelink)
        if [ -L "${t}" ] || [ ! -e "${t}" ]; then
          ln -sfn "${s}" "${t}"
        fi
        ;;
      copy)
        [ ! -e "${t}" ] && cp -rp "${s}" "${t}"
        ;;
      *)
        echo "unknown link mode '${mode}' in ${manifest} (line for ${target}), exiting..."
        exit 1
        ;;
    esac
  done < "${manifest}"
}

symlink_configs(){
  cd ~ || exit 1

  ## mac bespoke (everything else lives in scripts/links.conf)
  if [ "$system_os" = "macos" ]; then
    [ ! -d ~/iCloudDrive ] && [ -d ~/Library/Mobile\ Documents/com~apple~CloudDocs ] && \
      ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs ~/iCloudDrive
  fi

  ## all platforms: ssh config.d placeholder (both ssh_config forks include config.d/*)
  mkdir -p ~/.ssh/config.d
  [ ! -e ~/.ssh/config.d/ssh_config ] && touch ~/.ssh/config.d/ssh_config

  ## all bespoke
  if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    rm -f ~/.zshrc
  fi
  [ ! -d ~/tmp ] && mkdir ~/tmp
  [ ! -d ~/.emacs.d ] && mkdir ~/.emacs.d
  [ ! -d ~/.emacs.d/views ] && mkdir ~/.emacs.d/views
  [ ! -e ~/.emacs.d/views/agenda.html ] && touch ~/.emacs.d/views/agenda.html
  # virtualenvwrapper hooks (bootstrap originally linked these; only when the
  # dir already exists — virgin machines get the dir created without hooks)
  if [ -d ~/.virtualenvs ]; then
    ln -sfn "${DOTFILES_ROOT}/utils/virtualenvwrapper-zsh-hooks/postactivate" ~/.virtualenvs/postactivate
    ln -sfn "${DOTFILES_ROOT}/utils/virtualenvwrapper-zsh-hooks/postdeactivate" ~/.virtualenvs/postdeactivate
  else
    mkdir ~/.virtualenvs
  fi
  link_agent_skills

  ## manifest-driven links/copies
  backup_omarchy_configs
  apply_links
  seed_vicinae_shortcuts
  enable_user_units
}

# shortcuts.json is copy-once (Vicinae writes visit counts). If Vicinae created
# an empty file before the first deploy, copy skips and web-search fallbacks
# point at missing ids. Merge any repo ids the live file does not have.
seed_vicinae_shortcuts(){
  repo="${DOTFILES_ROOT}/omarchy/vicinae/shortcuts.json"
  live="${HOME}/.local/share/vicinae/shortcuts/shortcuts.json"
  [ -f "${repo}" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0
  added="$(python3 - "${repo}" "${live}" <<'PY'
import json, os, sys
repo, live = sys.argv[1], sys.argv[2]
with open(repo, encoding="utf-8") as f:
    baseline = json.load(f)
if not os.path.exists(live):
    raise SystemExit(0)
try:
    with open(live, encoding="utf-8") as f:
        current = json.load(f)
except (OSError, json.JSONDecodeError):
    raise SystemExit(0)
if not isinstance(current, list):
    raise SystemExit(0)
have = {s.get("id") for s in current if isinstance(s, dict)}
added = 0
for s in baseline:
    if isinstance(s, dict) and s.get("id") and s["id"] not in have:
        current.append(s)
        added += 1
if added:
    with open(live, "w", encoding="utf-8") as f:
        json.dump(current, f, indent=2)
        f.write("\n")
    print(added)
PY
)"
  [ -n "${added}" ] || return 0
  echo "seeded ${added} vicinae shortcut(s) into ${live}"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user try-restart vicinae.service 2>/dev/null || true
  fi
}

# Enable systemd user units (arch/omarchy only). Two sources:
#   1. units we ship in omarchy/systemd/user/ (linked via scripts/links.conf)
#   2. packaged units we depend on but do not vendor (vicinae.service from
#      vicinae-bin). Skip quietly when the package is not installed yet.
# Idempotent; safe over SSH (our shipped units gate themselves on a live
# graphical session via ConditionEnvironment).
enable_user_units(){
  [ "$system_os" = "arch" ] || return 0
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl --user daemon-reload 2>/dev/null
  for unit in "${DOTFILES_ROOT}"/omarchy/systemd/user/*.service; do
    [ -e "$unit" ] || continue
    name="$(basename "$unit")"
    if systemctl --user enable --now "$name" 2>/dev/null; then
      echo "user unit enabled: $name"
    else
      echo "could not enable user unit: $name (enable manually: systemctl --user enable --now $name)"
    fi
  done
  if [ -f /usr/lib/systemd/user/vicinae.service ]; then
    if systemctl --user enable --now vicinae.service 2>/dev/null; then
      echo "user unit enabled: vicinae.service"
    else
      echo "could not enable user unit: vicinae.service (enable manually: systemctl --user enable --now vicinae.service)"
    fi
  fi
}


## work begins here
if [ "${DOTFILES_LINKS_ONLY:-0}" = "1" ]; then
  # testing/maintenance mode: linking only, no repo update or package install
  echo "links-only mode: skipping repo update and package install..."
  os_setup
  symlink_configs
else
  update_repo
  os_setup
  verify_packages
  symlink_configs
  offer_login_shell_change
fi
echo ""
echo "setup complete!"
