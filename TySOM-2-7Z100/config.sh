#!/bin/bash

# Set the proper paths below
#(e.g. /$TOOLS_DIR/Aldec/Riviera-PRO-2021.10-x64)
#(e.g. /$TOOLS_DIR/Xilinx/Linux/petalinux-v2021.1)
#(e.g. /$TOOLS_DIR/Xilinx/Vivado/2021.1)

export RIVIERA_PATH=/edatools/aldec/riviera-pro-2021.10_64/
export PETALINUX_PATH=/edatools/Xilinx/PetaLinux/2022.1/tool/
export VIVADO_PATH=/edatools/Xilinx/Vivado/2022.1
export project_name=tysom2_petalinux

export SYNC_QUANTUM=100000
RPORT_PATH=../${project_name}/qemu_cosim/qemu-rport-_cosim@0
export RPORT_PATH_SC=${RPORT_PATH}
export RPORT_PATH_HDL=unix:${RPORT_PATH}
