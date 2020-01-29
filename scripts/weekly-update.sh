#!/usr/local/bin/zsh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r npm-pkgs.txt ] || [ ! -r gem-pkgs.txt ] || [ ! -r pip-pkgs.txt ] && { echo "missing package lists, exiting..." ; exit 1; }

## read in packages to install
npm_pkgs="$(grep '^[^#[:blank:]]' npm-pkgs.txt | tr '\n' ' ')"
gem_pkgs="$(grep '^[^#[:blank:]]' gem-pkgs.txt | tr '\n' ' ')"
pip_pkgs="$(grep '^[^#[:blank:]]' pip-pkgs.txt | tr '\n' ' ')"

## do it!
### in the install commands below, wrapping echo is for array->string conversion
. ~/.sh_aliases \
  && update-dotfiles \
  && brew update && brew doctor && brew upgrade; brew cleanup \
  && mas upgrade \
  && brew cu -a --cleanup \
  && npm install -g $(echo "${npm_pkgs}") \
  && gem install $(echo "${gem_pkgs}") && gem update \
  && brew install shellcheck lua luarocks hadolint && luarocks install luacheck \
  && pip install -U $(echo "${pip_pkgs}")
