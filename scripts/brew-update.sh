#!/bin/zsh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r brew-pkgs.txt ] && { echo "missing package list, exiting..." ; exit 1; }

## read in packages to install
brew_pkgs="$(grep '^[^#[:blank:]]' brew-pkgs.txt | tr '\n' ' ')"

## do it!
### in the install commands below, wrapping echo is for array->string conversion
. ~/.sh_aliases \
  && echo "updating brew packages..." \
  && brew update && brew doctor && brew upgrade; brew cleanup \
  && echo "installing missing brew packages..." \
  && brew install $(echo "${brew_pkgs}")
