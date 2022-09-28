#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source ./config.sh
source $RIVIERA_PATH/etc/setenv

cd hardware

$VIVADO_PATH/bin/vivado -mode batch -source reference_project.tcl
