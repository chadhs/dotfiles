#!/usr/bin/env bash

# vscode extensions

## include an uncommented list of extensions to install here

extensions=(
  "ms-azuretools.vscode-docker"
  "dbaeumer.vscode-eslint"
  "vscodevim.vim"
)

for extension in "${extensions[@]}"
do
  :
  code --install-extension "${extension}"
done
