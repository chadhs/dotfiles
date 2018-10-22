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
    package_list="editorconfig git tmux zsh"
    cask_package_list="emacs macvim"
  elif [ "$system_type" = "FreeBSD" ]; then
    system_os="freebsd"
    pkg_install="sudo pkg install -y"
    package_list="editorconfig-core-c emacs-nox11 git tmux vim-lite zsh"
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
  [ "$system_os" = "macos" ] && brew tap caskroom/cask && brew cask install $cask_package_list
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
    [ ! -d ~/.lein ] && mkdir .lein
    [ ! -e ~/.lein/profiles.clj ] && ln -s ~/dotfiles/utils/lein_profiles.clj .lein/profiles.clj
    [ ! -d ~/bin ] && mkdir ~/bin
    [ ! -e ~/bin/reload-safari.scpt ] && ln -s ~/dotfiles/utils/reload-safari.scpt ~/bin/reload-safari.scpt
    [ ! -e ~/bin/reload-chrome.scpt ] && ln -s ~/dotfiles/utils/reload-chrome.scpt ~/bin/reload-chrome.scpt
    [ ! -e ~/bin/macos-reset-routing-table.sh ] && ln -s ~/dotfiles/utils/macos-reset-routing-table.sh ~/bin/macos-reset-routing-table.sh
  fi


  # all
  [ ! -e ~/.profile ] && ln -s ~/dotfiles/shells/profile .profile
  [ ! -d ~/.oh-my-zsh ] && curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh; rm ~/.zshrc
  [ ! -e ~/.zshrc ] && ln -s ~/dotfiles/shells/zshrc .zshrc
  [ ! -e ~/.zprofile ] && ln -s ~/dotfiles/shells/zprofile .zprofile
  [ ! -e ~/.oh-my-zsh/themes/digitalnomad.zsh-theme ] && \
    ln -s ~/dotfiles/shells/digitalnomad.zsh-theme ~/.oh-my-zsh/themes/digitalnomad.zsh-theme
  [ ! -e ~/.bashrc ] && ln -s ~/dotfiles/shells/bashrc .bashrc
  [ ! -e ~/.bash_profile ] && ln -s ~/dotfiles/shells/bash_profile .bash_profile
  [ ! -e ~/.sh_aliases ] && ln -s ~/dotfiles/shells/sh_aliases .sh_aliases
  [ ! -e ~/.inputrc ] && ln -s ~/dotfiles/shells/inputrc .inputrc
  [ ! -e ~/.tmux.conf ] && ln -s ~/dotfiles/utils/tmux.conf .tmux.conf
  [ ! -d ~/tmp ] && mkdir ~/tmp
  [ ! -e ~/.vimrc ] && ln -s ~/dotfiles/editors/vimrc .vimrc
  [ ! -d ~/.vim ] && git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  vim +PluginClean! +qall
  vim +PluginInstall! +qall
  [ ! -d ~/.emacs.d ] && mkdir ~/.emacs.d
  [ ! -e ~/.emacs ] && ln -s ~/dotfiles/editors/emacs.el .emacs
  [ ! -e ~/.emacs.d/emacs-config.org ] && ln -s ~/dotfiles/editors/emacs-config.org ~/.emacs.d/emacs-config.org
  [ ! -e ~/.gitconfig ] && ln -s ~/dotfiles/utils/gitconfig_server .gitconfig
  [ ! -e ~/.editorconfig ] && ln -s ~/dotfiles/editors/editorconfig .editorconfig
  [ ! -e ~/.jshintrc ] && ln -s ~/dotfiles/utils/jshintrc .jshintrc
  [ ! -e ~/.jsbeautifyrc ] && ln -s ~/dotfiles/utils/jsbeautifyrc .jsbeautifyrc
  [ ! -e ~/.tern-config ] && ln -s ~/dotfiles/utils/tern-config .tern-config
  [ ! -e ~/.indium.json ] && ln -s ~/dotfiles/utils/indium.json .indium.json
}


## work begins here
update_repo
os_setup
verify_packages
symlink_configs
echo ""
echo "setup complete!"
