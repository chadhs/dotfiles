#!/bin/zsh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r mas-pkgs.txt ] && { echo "missing package list, exiting..." ; exit 1; }

## read in packages to install
mas_pkgs="$(grep '^[^#[:blank:]]' mas-pkgs.txt | tr '\n' ' ')"

## do it!
### in the install commands below, wrapping echo is for array->string conversion
. ~/.sh_aliases \
  && echo "updating mac app store apps..." \
  && mas outdated && mas outdated && rehash && mas upgrade \
  && echo "installing missing mac app store apps..." \
  && mas outdated && mas install $(echo "${mas_pkgs}")
