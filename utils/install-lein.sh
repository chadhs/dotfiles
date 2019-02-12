#!/bin/sh

lein_version=${1}

cd ~/bin || exit 1
rm lein
wget "https://raw.githubusercontent.com/technomancy/leiningen/${lein_version}/bin/lein"
chmod +x lein
ls -lah lein

exit 0
