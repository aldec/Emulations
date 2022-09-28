#!/bin/bash

source ./config.sh
rm -f RPORT_PATH
source $RIVIERA_PATH/etc/setenv
source $RIVIERA_PATH/etc/setgcc    
source $PETALINUX_PATH/settings.sh

xterm -e ./scripts/run_qemu.sh &
cd riviera
./run.sh
cd ..
