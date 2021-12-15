#!/bin/zsh
watchdir="$HOME/org"
filepattern="*.*"
filewatcher -D "${watchdir}/${filepattern}" "cd ${watchdir} && git pull && git add -A && git commit -a -m '[org update]' && git push"
exit 0
