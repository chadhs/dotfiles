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
    cask_package_list="emacs-app"
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

# Symlink each skill directory from src into dest. Skip missing globs and hidden names.
link_skills_from(){
  src="$1"
  dest="$2"
  for skill in "$src"/*; do
    [ -e "$skill" ] || continue
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    case "$name" in
      .*) continue ;;
    esac
    ln -sfn "$skill" "$dest/$name"
  done
}

# Merge repo + machine-local skill dirs into ~/.agents/skills as per-skill symlinks.
# Local names override shared names. ~/.claude/skills points at the merge dir.
link_agent_skills(){
  shared="$HOME/dotfiles/utils/agents/skills"
  local_dir="$HOME/.agents/skills-local"
  dest="$HOME/.agents/skills"

  mkdir -p "$shared" "$local_dir" "$dest" "$HOME/.claude"

  if [ -L "$dest" ]; then
    rm -f "$dest"
    mkdir -p "$dest"
  fi

  link_skills_from "$shared" "$dest"
  link_skills_from "$local_dir" "$dest"

  for entry in "$dest"/*; do
    [ -L "$entry" ] || continue
    name="$(basename "$entry")"
    case "$name" in
      .*) continue ;;
    esac
    if [ -d "$shared/$name" ] || [ -d "$local_dir/$name" ]; then
      continue
    fi
    rm -f "$entry"
  done

  if [ -L "$HOME/.claude/skills" ] || [ ! -e "$HOME/.claude/skills" ]; then
    ln -sfn "$dest" "$HOME/.claude/skills"
  fi
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
    mkdir -p ~/.config/git
    if [ -d ~/.config/git/hooks ] && [ ! -L ~/.config/git/hooks ]; then
      rm -rf ~/.config/git/hooks
    fi
    ln -sfn ~/dotfiles/utils/git-hooks ~/.config/git/hooks
    mkdir -p ~/.cursor/rules
    ln -sfn ~/dotfiles/utils/cursor/rules/no-cursor-attribution.mdc ~/.cursor/rules/no-cursor-attribution.mdc
    [ ! -d ~/.clojure ] && mkdir .clojure
    [ ! -e ~/.clojure/deps.edn ] && cp -rp ~/dotfiles/utils/deps.edn ~/.clojure/deps.edn
    [ ! -d ~/.lein ] && mkdir .lein
    [ ! -e ~/.lein/profiles.clj ] && cp -rp ~/dotfiles/utils/lein_profiles.clj ~/.lein/profiles.clj
    [ ! -d ~/bin ] && mkdir ~/bin
    [ ! -e ~/bin/reload-safari.scpt ] && ln -s ~/dotfiles/utils/reload-safari.scpt ~/bin/reload-safari.scpt
    [ ! -e ~/bin/reload-chrome.scpt ] && ln -s ~/dotfiles/utils/reload-chrome.scpt ~/bin/reload-chrome.scpt
    [ ! -e ~/bin/macos-reset-routing-table.sh ] && ln -s ~/dotfiles/utils/macos-reset-routing-table.sh ~/bin/macos-reset-routing-table.sh
    [ ! -d ~/iCloudDrive ] && [ -d ~/Library/Mobile\ Documents/com~apple~CloudDocs ] && ln -s ~/Library/Mobile\ Documents/com~apple~CloudDocs ~/iCloudDrive
    [ ! -e ~/.ideavimrc ] && ln -s ~/dotfiles/editors/ideavimrc .ideavimrc
    [ ! -e ~/Library/Application\ Support/espanso/match/common.yml ] && ln -s ~/dotfiles/utils/espanso/common.yml ~/Library/Application\ Support/espanso/match/common.yml
    [ ! -e ~/Library/Application\ Support/espanso/match/private.yml ] && cp -rp ~/dotfiles/utils/espanso/private.yml ~/Library/Application\ Support/espanso/match/private.yml
    [ ! -e ~/.config/karabiner/assets/complex_modifications/custom.json ] && ln -s ~/dotfiles/utils/karabiner/custom.json ~/.config/karabiner/assets/complex_modifications/custom.json
    mkdir -p ~/.config/ghostty
    [ ! -e ~/.config/ghostty/config ] && ln -s ~/dotfiles/utils/ghostty/config ~/.config/ghostty/config
    # Finder "Open With" → Ghostty + nvim (replaces occasional MacVim GUI use)
    ln -sfn ~/dotfiles/utils/Open\ in\ Neovim.app /Applications/Open\ in\ Neovim.app
    [ ! -e ~/bin/open-in-neovim.sh ] && ln -s ~/dotfiles/utils/open-in-neovim.sh ~/bin/open-in-neovim.sh
  fi


  # all
  [ ! -e ~/.profile ] && ln -s ~/dotfiles/shells/profile .profile
  if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    rm -f ~/.zshrc
  fi
  [ ! -e ~/.zshrc ] && ln -s ~/dotfiles/shells/zshrc .zshrc
  # PATH/env in zshenv only — zprofile is login-only and must not source profile.
  # Force-correct repo-managed symlinks so a pull of the split files can't leave
  # ~/.zshenv pointing at the empty zprofile stub (breaks Homebrew on PATH).
  if [ -L ~/.zshenv ] || [ ! -e ~/.zshenv ]; then
    ln -sfn ~/dotfiles/shells/zshenv ~/.zshenv
  fi
  if [ -L ~/.zprofile ] || [ ! -e ~/.zprofile ]; then
    ln -sfn ~/dotfiles/shells/zprofile ~/.zprofile
  fi
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
  [ ! -d ~/.config/nvim ] && ln -s ~/dotfiles/editors/nvim ~/.config/nvim
  [ ! -e ~/.gitconfig ] && ln -s ~/dotfiles/utils/gitconfig_server .gitconfig
  [ ! -e ~/.editorconfig ] && ln -s ~/dotfiles/editors/editorconfig .editorconfig
  [ ! -e ~/.eslintrc.json ] && ln -s ~/dotfiles/utils/eslintrc.json ~/.eslintrc.json
  [ ! -e ~/.prettierrc.json ] && ln -s ~/dotfiles/utils/prettierrc.json ~/.prettierrc.json
  [ ! -e ~/jsconfig.json ] && ln -s ~/dotfiles/utils/jsconfig.json ~/jsconfig.json
  [ ! -e ~/.zprint.edn ] && ln -s ~/dotfiles/utils/zprint.edn .zprint.edn
  [ ! -d ~/.virtualenvs ] && mkdir ~/.virtualenvs
  link_agent_skills
}


## work begins here
update_repo
os_setup
verify_packages
symlink_configs
echo ""
echo "setup complete!"
