#!/bin/bash

source ./config.sh
source $PETALINUX_PATH/settings.sh $PETALINUX_PATH

./scripts/build_petalinux_project.sh
./scripts/generate_qemu_device_tree_zynq7.sh ./$project_name

