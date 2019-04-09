#!/usr/local/bin/zsh

npm_pkgs="$(grep '^[^#[:blank:]]' npm-pkgs.txt | tr '\n' ' ')"
gem_pkgs="$(grep '^[^#[:blank:]]' gem-pkgs.txt | tr '\n' ' ')"
pip_pkgs="$(grep '^[^#[:blank:]]' pip-pkgs.txt | tr '\n' ' ')"
# in the install commands below, wrapping echo is for array->string conversion

. ~/.sh_aliases \
  && update-tech-notes && update-dotfiles \
  && brew update && brew doctor && brew upgrade; brew cleanup \
  && mas upgrade \
  && brew cu -a --cleanup \
  && npm install -g $(echo "${npm_pkgs}") \
  && gem install $(echo "${gem_pkgs}") && gem update \
  && brew install shellcheck lua luarocks hadolint && luarocks install luacheck \
  && pip install -U pip && pip install -U $(echo "${pip_pkgs}")
