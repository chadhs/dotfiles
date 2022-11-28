#!/usr/bin/env bash

# vscode extensions

## include an uncommented list of extensions to install here

extensions=(
  ## core
  "vscodevim.vim"
  "editorconfig.editorconfig"
  "lucax88x.codeacejumper"
  "ms-azuretools.vscode-docker"
  ## langs
  ### javascript/typescript
  "dbaeumer.vscode-eslint"
  ### clojure
  "betterthantomorrow.calva"
  "borkdude.clj-kondo"
  "humao.rest-client"
  ### java
  "vscjava.vscode-java-pack"
  "vscjava.vscode-gradle"
)

for extension in "${extensions[@]}"
do
  :
  code --install-extension "${extension}"
done
