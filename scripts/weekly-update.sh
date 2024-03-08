#!/bin/zsh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r npm-pkgs.txt ] || [ ! -r gem-pkgs.txt ] || [ ! -r pip-pkgs.txt ] && { echo "missing package lists, exiting..." ; exit 1; }

## read in packages to install
brew_pkgs="$(grep '^[^#[:blank:]]' brew-pkgs.txt | tr '\n' ' ')"
cask_pkgs="$(grep '^[^#[:blank:]]' cask-pkgs.txt | tr '\n' ' ')"
mas_pkgs="$(grep '^[^#[:blank:]]' mas-pkgs.txt | tr '\n' ' ')"
npm_pkgs="$(grep '^[^#[:blank:]]' npm-pkgs.txt | tr '\n' ' ')"
gem_pkgs="$(grep '^[^#[:blank:]]' gem-pkgs.txt | tr '\n' ' ')"
pip_pkgs="$(grep '^[^#[:blank:]]' pip-pkgs.txt | tr '\n' ' ')"

## do it!
### in the install commands below, wrapping echo is for array->string conversion
echo "updating packages..."
. ~/.sh_aliases \
  && update-dotfiles \
  && brew update && brew doctor && brew upgrade; brew cleanup \
  && mas outdated && rehash && mas upgrade \
  && brew cu -a --cleanup \
  && npm install -g $(echo "${npm_pkgs}") \
  && gem install $(echo "${gem_pkgs}") && gem update \
  && brew install shellcheck lua luarocks hadolint && luarocks install luacheck \
  && pip3 install -U --break-system-packages $(echo "${pip_pkgs}") \
  && echo "installing missing brew packages..." \
  && brew install $(echo "${brew_pkgs}") \
  && echo "installing missing brew cask packages..." \
  && brew install --cask $(echo "${cask_pkgs}") \
  && echo "installing missing mac app store apps..." \
  && mas outdated && mas install $(echo "${mas_pkgs}")
