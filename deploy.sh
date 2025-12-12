#!/bin/sh
# dotfiles deploy


## helpers
update_repo(){
  cd ~/dotfiles || exit 1
  git pull -q
}

os_setup(){
  system_type="$(uname)"
  if [ "$system_type" = "Darwin" ]; then
    system_os="macos"
    pkg_install="brew install"
    package_list="editorconfig git nvim tmux zsh"
    cask_package_list="emacs-app macvim-app"
  elif [ "$system_type" = "FreeBSD" ]; then
    system_os="freebsd"
    pkg_install="sudo pkg install -y"
    package_list="editorconfig-core-c emacs-nox11 git tmux vim-console zsh"
  elif [ "$system_type" = "Linux" ]; then
    if [ -n "$(grep -i "ubuntu" /proc/version)" ] || [ -n "$(grep -i "debian" /proc/version)" ]; then
      system_os="debian"
      pkg_install="sudo apt-get install -y"
      package_list="editorconfig  emacs-nox git tmux vim-nox zsh"
    elif [ -n "$(grep -i "red hat" /proc/version)" ]; then
      ### enable epel repo to have access to expanded package library
      sudo yum install -y epel-release
      system_os="redhat"
      pkg_install="sudo yum install -y"
      package_list="emacs-nox git tmux vim-enhanced zsh"
    fi
  fi
  echo "setting up your dotfiles and default packages for a $system_os system..."
  echo ""
}

verify_packages(){
  $pkg_install $package_list
  [ "$system_os" = "macos" ] && brew install --cask $cask_package_list
}

symlink_configs(){
  cd ~ || exit 1

  # mac
  if [ "$system_os" = "macos" ]; then
    [ ! -d ~/.ssh ] && mkdir ~/.ssh
    [ ! -d ~/.ssh/config.d ] && mkdir ~/.ssh/config.d
    [ ! -e ~/.ssh/config ] && ln -s ~/dotfiles/utils/ssh_config ~/.ssh/config
    [ ! -e ~/.ssh/config.d/ssh_config ] && touch ~/.ssh/config.d/ssh_config
    [ ! -e ~/.gitconfig ] && ln -s ~/dotfiles/utils/gitconfig .gitconfig
    [ ! -e ~/.gitconfig-local ] && cp -rp ~/dotfiles/utils/gitconfig-local ~/.gitconfig-local
    [ ! -d ~/.gitconfig.d ] && cp -rp ~/dotfiles/utils/gitconfig.d ~/.gitconfig.d
    [ ! -d ~/.clojure ] && mkdir .clojure
    [ ! -e ~/.clojure/deps.edn ] && cp -rp ~/dotfiles/utils/deps.edn ~/.clojure/deps.edn
    [ ! -d ~/.lein ] && mkdir .lein
    [ ! -e ~/.lein/profiles.clj ] && cp -rp ~/dotfiles/utils/lein_profiles.clj ~/.lein/profiles.clj
    [ ! -d ~/bin ] && mkdir ~/bin
    [ ! -e ~/bin/reload-safari.scpt ] && ln -s ~/dotfiles/utils/reload-safari.scpt ~/bin/reload-safari.scpt
    [ ! -e ~/bin/reload-chrome.scpt ] && ln -s ~/dotfiles/utils/reload-chrome.scpt ~/bin/reload-chrome.scpt
    [ ! -e ~/bin/macos-reset-routing-table.sh ] && ln -s ~/dotfiles/utils/macos-reset-routing-table.sh ~/bin/macos-reset-routing-table.sh
    [ ! -d ~/iCloudDrive ] && [ -d ~/Library/Mobile\ Documents/com~apple~CloudDocs ] && ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs ~/iCloudDrive
    [ ! -d ~/Library/Application\ Support/Code/User ] && mkdir -p ~/Library/Application\ Support/Code/User
    [ ! -e ~/.vscodevimrc ] && ln -s ~/dotfiles/editors/vscode/vscodevimrc ~/.vscodevimrc
    [ ! -e ~/.ideavimrc ] && ln -s ~/dotfiles/editors/ideavimrc .ideavimrc
    [ ! -e ~/Library/Application\ Support/espanso/match/common.yml ] && ln -s ~/dotfiles/utils/espanso/common.yml ~/Library/Application\ Support/espanso/match/common.yml
    [ ! -e ~/Library/Application\ Support/espanso/match/private.yml ] && cp -rp ~/dotfiles/utils/espanso/private.yml ~/Library/Application\ Support/espanso/match/private.yml
    [ ! -e ~/.config/karabiner/assets/complex_modifications/custom.json ] && ln -s ~/dotfiles/utils/karabiner/custom.json ~/.config/karabiner/assets/complex_modifications/custom.json
    [ ! -d ~/.config/kitty ] && mkdir ~/.config/kitty && ln -s ~/dotfiles/utils/kitty/kitty.conf ~/.config/kitty/kitty.conf && ln -s ~/dotfiles/utils/kitty/kitty.app.png ~/.config/kitty/kitty.app.png && ln -s ~/dotfiles/utils/kitty/current-theme.conf ~/.config/kitty/current-theme.conf
    [ ! -d ~/.config/ghostty ] && mkdir ~/.config/ghostty && ln -s ~/dotfiles/utils/ghostty/config ~/.config/ghostty/config
  fi


  # all
  [ ! -e ~/.profile ] && ln -s ~/dotfiles/shells/profile .profile
  [ ! -d ~/.oh-my-zsh ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; rm ~/.zshrc
  [ ! -e ~/.zshrc ] && ln -s ~/dotfiles/shells/zshrc .zshrc
  [ ! -e ~/.zprofile ] && ln -s ~/dotfiles/shells/zprofile .zprofile
  [ ! -e ~/.zshenv ] && ln -s ~/dotfiles/shells/zprofile .zshenv
  [ ! -e ~/.user-env ] && cp ~/dotfiles/shells/user-env ~/.user-env
  [ ! -e ~/.oh-my-zsh/themes/digitalnomad.zsh-theme ] && \
    ln -s ~/dotfiles/shells/digitalnomad.zsh-theme ~/.oh-my-zsh/themes/digitalnomad.zsh-theme
  [ ! -e ~/.bashrc ] && ln -s ~/dotfiles/shells/bashrc .bashrc
  [ ! -e ~/.bash_profile ] && ln -s ~/dotfiles/shells/bash_profile .bash_profile
  [ ! -e ~/.sh_aliases ] && ln -s ~/dotfiles/shells/sh_aliases .sh_aliases
  [ ! -e ~/.inputrc ] && ln -s ~/dotfiles/shells/inputrc .inputrc
  [ ! -e ~/.tmux.conf ] && ln -s ~/dotfiles/utils/tmux.conf .tmux.conf
  [ ! -d ~/tmp ] && mkdir ~/tmp
  [ ! -d ~/.emacs.d ] && mkdir ~/.emacs.d
  [ ! -d ~/.emacs.d/lisp ] && ln -s ~/dotfiles/editors/emacs.d/lisp ~/.emacs.d/lisp
  [ ! -d ~/.emacs.d/snippets ] && ln -s ~/dotfiles/editors/emacs.d/snippets ~/.emacs.d/snippets
  [ ! -d ~/.emacs.d/views ] && mkdir ~/.emacs.d/views
  [ ! -e ~/.emacs.d/views/agenda.html ] && touch ~/.emacs.d/views/agenda.html
  [ ! -e ~/.emacs ] && ln -s ~/dotfiles/editors/emacs.el .emacs
  [ ! -e ~/.emacs.d/emacs-config.org ] && ln -s ~/dotfiles/editors/emacs-config.org ~/.emacs.d/emacs-config.org
  [ ! -e ~/.vimrc ] && ln -s ~/dotfiles/editors/vimrc .vimrc
  [ ! -d ~/.vim ] && git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  ## deprecated
  # vim +PluginClean! +qall
  # vim +PluginInstall! +qall
  [ ! -d ~/.config/nvim ] && ln -s ~/dotfiles/editors/nvim ~/.config/nvim
  [ ! -e ~/.gitconfig ] && ln -s ~/dotfiles/utils/gitconfig_server .gitconfig
  [ ! -e ~/.editorconfig ] && ln -s ~/dotfiles/editors/editorconfig .editorconfig
  [ ! -e ~/.eslintrc.json ] && ln -s ~/dotfiles/utils/eslintrc.json ~/.eslintrc.json
  [ ! -e ~/.prettierrc.json ] && ln -s ~/dotfiles/utils/prettierrc.json ~/.prettierrc.json
  [ ! -e ~/jsconfig.json ] && ln -s ~/dotfiles/utils/jsconfig.json ~/jsconfig.json
  [ ! -e ~/.tern-config ] && ln -s ~/dotfiles/utils/tern-config .tern-config
  [ ! -e ~/.indium.json ] && ln -s ~/dotfiles/utils/indium.json .indium.json
  [ ! -e ~/.zprint.edn ] && ln -s ~/dotfiles/utils/zprint.edn .zprint.edn
  [ ! -d ~/.virtualenvs ] && mkdir ~/.virtualenvs
}


## work begins here
update_repo
os_setup
verify_packages
symlink_configs
echo ""
echo "setup complete!"
