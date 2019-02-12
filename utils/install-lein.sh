#!/bin/sh

cd ~/bin || exit 1
rm lein
wget https://raw.githubusercontent.com/technomancy/leiningen/2.8.3/bin/lein
chmod +x lein
ls -lah lein

exit 0
