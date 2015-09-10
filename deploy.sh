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
		system_os="mac"
		pkg_install="brew install"
		package_list="macvim --override-system-vim git tmux zsh"
	elif [ "$system_type" = "FreeBSD" ]; then
		system_os="freebsd"
		pkg_install="sudo pkg install -y"
		package_list="vim git tmux zsh cmake"
	elif [ "$system_type" = "Linux" ]; then
		if [ -n "$(grep -i "ubuntu" /proc/version)" ] || [ -n "$(grep -i "debian" /proc/version)" ]; then
			system_os="debian"
			pkg_install="sudo apt-get install -y"
			package_list="vim git tmux zsh build-essential"
		elif [ -n "$(grep -i "red hat" /proc/version)" ]; then
			system_os="redhat"
			pkg_install="sudo yum install -y"
			package_list="vim git tmux zsh @development-tools"
		fi
	fi
	echo "setting up your dotfiles and default packages for a $system_os system..."
	echo ""
}

verify_packages(){
	$pkg_install $package_list
}

symlink_configs(){
	cd ~ || exit 1

	# mac
	[ "$system_os" = "mac" ] && [ ! -d ~/.ssh ] && ln -s ~/Dropbox/configs/ssh .ssh

	# all
	[ ! -d ~/.oh-my-zsh ] && curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh \
		; rm ~/.zshrc
	[ ! -e ~/.zshrc ] && ln -s ~/dotfiles/shells/zshrc .zshrc
	[ ! -e ~/.oh-my-zsh/themes/digitalnomad.zsh-theme ] && \
		ln -s ~/dotfiles/shells/digitalnomad.zsh-theme ~/.oh-my-zsh/themes/digitalnomad.zsh-theme
	[ ! -e ~/.inputrc ] && ln -s ~/dotfiles/shells/inputrc .inputrc
	[ ! -e ~/.tmux.conf ] && ln -s ~/dotfiles/utils/tmux.conf .tmux.conf
	[ ! -d ~/tmp ] && mkdir ~/tmp
	[ ! -e ~/.vimrc ] && ln -s ~/dotfiles/editors/vimrc .vimrc
	[ ! -d ~/.vim ] && git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	[ ! -e ~/.spacemacs ] && ln -s ~/dotfiles/editors/spacemacs .spacemacs
	[ ! -e ~/.gitconfig ] && ln -s ~/dotfiles/utils/gitconfig .gitconfig
}


## work begins here
update_repo
os_setup
verify_packages
symlink_configs
echo ""
echo "setup complete!"
