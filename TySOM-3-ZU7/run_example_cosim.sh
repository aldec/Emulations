#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source ./config.sh
rm -rf ./$project_name/qemu_cosim/tmp/
mkdir -p ./$project_name/qemu_cosim/tmp/

source $RIVIERA_PATH/etc/setenv
source $RIVIERA_PATH/etc/setgcc    
source $PETALINUX_PATH/settings.sh

xterm -e ./scripts/run_qemu.sh &
cd riviera
./run.sh
cd ..
