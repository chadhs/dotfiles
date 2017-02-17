#!/bin/sh

echo "you will be prompted for your appleid and password once install tools are bootstrapped."
echo "be aware there will also be various password prompts during the install process for some packages."
sleep 3

echo "bootstraping install tools..."
xcode-select --install
[ -z $(command -v brew) ] && /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install mas
brew tap caskroom/cask

echo "installing mac app store apps..."
## here are the app to id mappings for convenience:
## 931657367 Calcbot, 918858936 Airmail, 496437906 Shush, 411643860 DaisyDisk, 407963104 Pixelmator, 872515009 Pomodoro Timer, 557168941 Tweetbot, 992076693 MindNode, 847496013 Deckset, 413965349 Soulver, 482898991 LiveReload, 924726344 Deliveries, 445189367 PopClip
read -p "enter your appleid email address: " appleid
mas signin ${appleid}
mas install 931657367 918858936 496437906 411643860 407963104 872515009 557168941 992076693 847496013 413965349 482898991 924726344 445189367

echo "installing open-source tools..."
brew install ansible aspell awscli bash ctags editorconfig git leiningen mit-scheme nmap node pandoc planck rlwrap ssh-copy-id terraform the_silver_searcher tmux tree wget zsh
brew cask install emacs macvim

echo "seting up dotfiles..."
cd ~ || exit 1
[ ! -d ~/dotfiles ] && git clone https://github.com/chadhs/dotfiles.git
sh dotfiles/deploy.sh

echo "installing non mac app store apps..."
brew cask install 1password alfred anvil appcleaner bartender caffeine choosy dash dropbox dropzone fantastical flux google-chrome google-hangouts hazel iterm2 keyboard-maestro moom nvalt omnifocus omnifocus-clip-o-tron slack spotify taskpaper textexpander textual the-unarchiver tripmode tunnelblick vagrant vagrant-manager virtualbox virtualbox-extension-pack

echo "don't forget to fetch any ssh keys you need from your secure vault!"

echo "finished, enjoy your mac!"
