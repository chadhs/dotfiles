#!/bin/zsh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r cask-pkgs.txt ] && { echo "missing package list, exiting..." ; exit 1; }

## read in packages to install
cask_pkgs="$(grep '^[^#[:blank:]]' cask-pkgs.txt | tr '\n' ' ')"

## do it!
### in the install commands below, wrapping echo is for array->string conversion
. ~/.sh_aliases \
  && echo "updating brew cask packages..." \
  && brew cu -a --cleanup \
  && echo "installing missing brew cask packages..." \
  && brew install --cask $(echo "${cask_pkgs}")
