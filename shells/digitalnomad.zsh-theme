# digitalnomad.zsh-theme
## a modification of fino.zsh-theme
## contact: helpme@chadstovern.com

## some notes fino author
# Use with a dark background and 256-color terminal!
# You can set your computer name in the ~/.box-name file if you want.

# Borrowing shamelessly from these oh-my-zsh themes:
#   bira
#   robbyrussell
#
# Also borrowing from http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt/

function prompt_char {
  git branch >/dev/null 2>/dev/null && echo "±" && return
  echo '○'
}

function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || echo $SHORT_HOST || echo $HOST
}

local current_dir='${PWD/#$HOME/~}'
local git_info='$(git_prompt_info)'
local prompt_char='$(prompt_char)'

function virtualenv_info {
	[ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

#PROMPT="╭─%{$FG[040]%}%n%{$reset_color%}%{$FG[239]%}@%{$reset_color%}%{$FG[033]%}$(box_name)%{$reset_color%} %{$FG[239]%}in%{$reset_color%} %{$terminfo[bold]$FG[226]%}${current_dir}%{$reset_color%}${git_info}
#╰─$(virtualenv_info)${prompt_char}%{$reset_color%} "
#PROMPT="╭─%{$FG[040]%}%n%{$reset_color%}%{$FG[239]%}@%{$reset_color%}%{$FG[033]%}$(box_name)%{$reset_color%} %{$FG[239]%}in%{$reset_color%} %{$terminfo[bold]$fg[magenta]%}${current_dir}%{$reset_color%}${git_info}
PROMPT="╭─%{$fg[green]%}%n%{$reset_color%}%{$FG[239]%}@%{$reset_color%}%{$fg[blue]%}$(box_name)%{$reset_color%} %{$FG[239]%}in%{$reset_color%} %{$terminfo[bold]%}${current_dir}%{$reset_color%}${git_info}
╰─$(virtualenv_info)${prompt_char}%{$reset_color%} "

#ZSH_THEME_GIT_PROMPT_PREFIX=" %{$FG[239]%}on%{$reset_color%} %{$fg[255]%}"
ZSH_THEME_GIT_PROMPT_PREFIX=" %{$FG[239]%}on%{$reset_color%} %{$fg[255]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
#ZSH_THEME_GIT_PROMPT_DIRTY="%{$FG[202]%} ✘"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%} ✘"
#ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$FG[202]%} +"
#ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[040]%} ✔"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[green]%} ✔"
