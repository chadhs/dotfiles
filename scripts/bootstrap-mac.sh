#!/bin/sh

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r mas-pkgs.txt ] || [ ! -r brew-pkgs.txt ] || [ ! -r cask-pkgs.txt ] && { echo "missing package lists, exiting..." ; exit 1; }

## read in packages to install
mas_pkgs="$(grep '^[^#[:blank:]]' mas-pkgs.txt | tr '\n' ' ')"
brew_pkgs="$(grep '^[^#[:blank:]]' brew-pkgs.txt | tr '\n' ' ')"
cask_pkgs="$(grep '^[^#[:blank:]]' cask-pkgs.txt | tr '\n' ' ')"

## do it!
#echo "you will be prompted for your appleid and password once install tools are bootstrapped."
echo "be aware there will be various password prompts during the install process for some packages."
sleep 3

echo "bootstraping install tools..."
xcode-select --install
[ -z "$(command -v brew)" ] && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
[ -z "$(command -v brew)" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
brew install mas
brew tap homebrew/cask-versions
brew tap buo/cask-upgrade

echo "installing mac app store apps..."
mas install $(echo "${mas_pkgs}") # wrapping echo is for array->string conversion

echo "installing open-source tools..."
sudo xcodebuild -license accept
brew install $(echo "${brew_pkgs}") # wrapping echo is for array->string conversion

echo "installing non mac app store apps..."
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew install --cask $(echo "${cask_pkgs}") # wrapping echo is for array->string conversion

echo "seting up dotfiles..."
cd ~ || exit 1
pip3 install virtualenvwrapper
[ ! -d ~/dotfiles ] && git clone https://github.com/chadhs/dotfiles.git
sh dotfiles/deploy.sh
[ -d ~/.virtualenvs ] && rm ~/.virtualenvs/postactivate && ln -s ~/dotfiles/utils/virtualenvwrapper-zsh-hooks/postactivate ~/.virtualenvs/postactivate
[ -d ~/.virtualenvs ] && rm ~/.virtualenvs/postdeactivate && ln -s ~/dotfiles/utils/virtualenvwrapper-zsh-hooks/postdeactivate ~/.virtualenvs/postdeactivate

echo "don't forget to fetch any ssh keys you need from your secure vault!"
echo "don't forget to fetch any gnupg keys you need from your secure vault!"
echo "don't forget to fetch any aws creds you need from your secure vault!"
echo "don't forget to migrate your shell,db,lang history files from your backups!"

echo "finished, enjoy your mac!"
