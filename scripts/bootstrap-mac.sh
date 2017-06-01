#!/bin/sh

# - set group write perms for admin in cellar and cask areas

## preflight checks
[ $(dirname "${0}") != "." ] && { echo "please run from within scripts dir, exiting..." ; exit 1; }
[ ! -r mas-pkgs.txt ] && cp -pv mas-pkgs.txt.example mas-pkgs.txt && edit_pkg_lists="true"
[ ! -r brew-pkgs.txt ] && cp -pv brew-pkgs.txt.example brew-pkgs.txt && edit_pkg_lists="true"
[ ! -r cask-pkgs.txt ] && cp -pv cask-pkgs.txt.example cask-pkgs.txt && edit_pkg_lists="true"
[ "${edit_pkg_lists}" = "true" ] && { echo "*-pkgs.txt files created, please edit and re-run this script, exiting..." ; exit 1; }
[ ! -r mas-pkgs.txt ] || [ ! -r brew-pkgs.txt ] || [ ! -r cask-pkgs.txt ] && { echo "missing package lists, exiting..." ; exit 1; }

## read in packages to install
mas_pkgs="$(grep '^[^#[:blank:]]' mas-pkgs.txt | tr '\n' ' ')"
brew_pkgs="$(grep '^[^#[:blank:]]' brew-pkgs.txt | tr '\n' ' ')"
cask_pkgs="$(grep '^[^#[:blank:]]' cask-pkgs.txt | tr '\n' ' ')"

## do it!
echo "you will be prompted for your appleid and password once install tools are bootstrapped."
echo "be aware there will also be various password prompts during the install process for some packages."
sleep 3

echo "bootstraping install tools..."
xcode-select --install
[ -z "$(command -v brew)" ] && /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install mas
brew tap caskroom/cask

echo "installing mac app store apps..."
read -rp "enter your appleid email address: " appleid
mas signin "${appleid}"
mas install $(echo "${mas_pkgs}") # wrapping echo is for array->string conversion

echo "installing open-source tools..."
brew install $(echo "${brew_pkgs}") # wrapping echo is for array->string conversion

echo "installing non mac app store apps..."
brew cask install $(echo "${cask_pkgs}") # wrapping echo is for array->string conversion

echo "seting up dotfiles..."
cd ~ || exit 1
pip install virtualenvwrapper
[ ! -d ~/dotfiles ] && git clone https://github.com/chadhs/dotfiles.git
sh dotfiles/deploy.sh

echo "fixing homebrew & homebrew cask permissions"
sudo chgrp -R admin /usr/local; sudo chmod -R g+w /usr/local

echo "don't forget to fetch any ssh keys you need from your secure vault!"

echo "finished, enjoy your mac!"
