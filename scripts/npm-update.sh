#!/bin/zsh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r npm-pkgs.txt ] && { echo "missing package list, exiting..." ; exit 1; }

## read in packages to install
npm_pkgs="$(grep '^[^#[:blank:]]' npm-pkgs.txt | tr '\n' ' ')"

## do it!
### in the install commands below, wrapping echo is for array->string conversion
. ~/.sh_aliases \
  && npm install -g $(echo "${npm_pkgs}") \
