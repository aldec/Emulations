#!/bin/bash

# Set the proper paths below
#(e.g. /$TOOLS_DIR/Aldec/Riviera-PRO-2022.04-x64)
#(e.g. /$TOOLS_DIR/Xilinx/Linux/petalinux-v2022.1)
#(e.g. /$TOOLS_DIR/Xilinx/Vivado/2022.1)

export RIVIERA_PATH=/path/to/riviera-pro-2022.04
export PETALINUX_PATH=/path/to/Xilinx/PetaLinux/2022.1/tool/
export VIVADO_PATH=/path/to/Xilinx/Vivado/2022.1
export project_name=tysom3_petalinux


export SYNC_QUANTUM=10000000
RPORT_PATH=../${project_name}/qemu_cosim/tmp/qemu-rport-_amba@0_cosim@0
export RPORT_PATH_SC=${RPORT_PATH}
export RPORT_PATH_HDL=unix:${RPORT_PATH}
