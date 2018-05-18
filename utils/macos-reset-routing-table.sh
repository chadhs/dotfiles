#!/bin/sh
# Reset routing table on macOS

# display current routing table
echo "********** BEFORE ****************************************"
netstat -rn
echo "**********************************************************"

for i in {0..4}; do
  sudo route -n flush # several times
done

echo "********** AFTER *****************************************"
netstat -rn
echo "**********************************************************"

echo "Bringing interface down..."
sudo ifconfig en0 down
sleep 1
echo "Bringing interface back up..."
sudo ifconfig en0 up
sleep 1

echo "********** FINALLY ***************************************"
netstat -rn
echo "**********************************************************"
