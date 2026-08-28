#!/bin/sh
set -eu

## resolve paths (safe to run from anywhere)
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname "${0}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "${SCRIPT_DIR}/.." && pwd)"
BREWFILE="${REPO_ROOT}/Brewfile"

## preflight checks
[ -r "${BREWFILE}" ] || { echo "missing Brewfile at ${BREWFILE}, exiting..." ; exit 1; }

## helpers
have_clt() {
  xcode-select -p >/dev/null 2>&1
}

wait_for_clt() {
  if have_clt; then
    return 0
  fi
  echo "requesting Xcode Command Line Tools install (GUI prompt)..."
  xcode-select --install >/dev/null 2>&1 || true
  echo "waiting for Command Line Tools to finish installing..."
  echo "(complete the macOS dialog if it is open)"
  while ! have_clt; do
    sleep 5
  done
  echo "Command Line Tools ready."
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  echo "installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon default prefix; fall back to Intel
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1 || { echo "brew not on PATH after install, exiting..." ; exit 1; }
}

## do it!
echo "be aware there will be various password prompts during the install process for some packages."
sleep 3

echo "bootstrapping install tools..."
wait_for_clt
ensure_brew

echo "installing packages from Brewfile..."
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew bundle --file="${BREWFILE}"

echo "accepting Xcode license if needed..."
sudo xcodebuild -license accept >/dev/null 2>&1 || true

echo "setting up macOS defaults..."
sh "${SCRIPT_DIR}/macos-defaults.sh"

echo "setting up dotfiles..."
if [ ! -d "${HOME}/dotfiles" ]; then
  if [ "${REPO_ROOT}" != "${HOME}/dotfiles" ]; then
    echo "cloning dotfiles into ~/dotfiles (repo currently at ${REPO_ROOT})..."
    git clone https://github.com/chadhs/dotfiles.git "${HOME}/dotfiles"
  fi
fi
# prefer the in-place repo when already running from ~/dotfiles
DOTFILES_ROOT="${HOME}/dotfiles"
[ -d "${DOTFILES_ROOT}" ] || DOTFILES_ROOT="${REPO_ROOT}"
sh "${DOTFILES_ROOT}/deploy.sh"

if [ -d "${HOME}/.virtualenvs" ]; then
  rm -f "${HOME}/.virtualenvs/postactivate" "${HOME}/.virtualenvs/postdeactivate"
  ln -s "${DOTFILES_ROOT}/utils/virtualenvwrapper-zsh-hooks/postactivate" "${HOME}/.virtualenvs/postactivate"
  ln -s "${DOTFILES_ROOT}/utils/virtualenvwrapper-zsh-hooks/postdeactivate" "${HOME}/.virtualenvs/postdeactivate"
fi

# use Homebrew zsh when available
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [ -x "${BREW_ZSH}" ]; then
  if ! grep -q "^${BREW_ZSH}$" /etc/shells 2>/dev/null; then
    echo "adding ${BREW_ZSH} to /etc/shells (sudo)..."
    echo "${BREW_ZSH}" | sudo tee -a /etc/shells >/dev/null
  fi
  if [ "${SHELL:-}" != "${BREW_ZSH}" ]; then
    echo "switching default shell to ${BREW_ZSH}..."
    chsh -s "${BREW_ZSH}" || echo "chsh failed; run: chsh -s ${BREW_ZSH}"
  fi
fi

echo "don't forget to fetch any ssh keys you need from your secure vault!"
echo "don't forget to fetch any gnupg keys you need from your secure vault!"
echo "don't forget to fetch any aws creds you need from your secure vault!"
echo "don't forget to migrate your shell,db,lang history files from your backups!"

echo "finished, enjoy your mac!"
