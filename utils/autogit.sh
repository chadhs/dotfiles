#!/bin/zsh
watchdir="$HOME/notes"
filepattern="*.*"
filewatcher -D "${watchdir}/${filepattern}" "cd ${watchdir} && git pull && git add -A && git commit -a -m 'notes update' && git push"
exit 0
