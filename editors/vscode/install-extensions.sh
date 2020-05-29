#!/usr/bin/env bash

# vscode extensions

## include an uncommented list of extensions to install here

extensions=(
  ## core
  "vscodevim.vim"
  "editorconfig.editorconfig"
  "coenraads.bracket-pair-colorizer-2"
  "ms-azuretools.vscode-docker"
  ## langs
  ### javascript/typescript
  "dbaeumer.vscode-eslint"
  ### clojure
  "betterthantomorrow.calva"
  "borkdude.clj-kondo"
)

for extension in "${extensions[@]}"
do
  :
  code --install-extension "${extension}"
done
