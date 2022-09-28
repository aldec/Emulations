#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

source ./config.sh

cp -f hardware/reference_project/reference_project.sim/sim_1/behav/riviera/design_1_wrapper_compile.do riviera
cp -f hardware/reference_project/reference_project.sim/sim_1/behav/riviera/design_1_wrapper_simulate.do riviera

sed -i 's:../../../../:../hardware/reference_project/:g' ./riviera/design_1_wrapper_compile.do
sed -i 's:glbl.v:../src/glbl.v:g' ./riviera/design_1_wrapper_compile.do
sed -i '/quit -force/d' ./riviera/design_1_wrapper_compile.do
sed -i '/transcript off/d' ./riviera/design_1_wrapper_compile.do
sed -i '/transcript on/d' ./riviera/design_1_wrapper_compile.do
sed -i 's:/[[:alnum:]/]\+/Xilinx/Vivado/2022\.1:\$env(VIVADO_PATH):g' ./riviera/design_1_wrapper_compile.do
sed -i '/transcript off/d' ./riviera/design_1_wrapper_simulate.do
sed -i '/transcript on/d' ./riviera/design_1_wrapper_simulate.do
sed -i '/onbreak {quit -force}/d' ./riviera/design_1_wrapper_simulate.do
sed -i s':onerror {quit -force}:set GENERIC_PATH /design_1_wrapper/design_1_i/zynq_ultra_ps_e_0/QEMU_PATH_TO_SOCKET_G \
echo $GENERIC_PATH \
set QUANTUM_GENERIC_PATH /design_1_wrapper/design_1_i/zynq_ultra_ps_e_0/QEMU_SYNC_QUANTUM_G \
echo \$QUANTUM_GENERIC_PATH \
set SIM_OPT \"-ieee_nowarn -i 5000 -t 1ps -relax +notimingchecks +access +r \":' ./riviera/design_1_wrapper_simulate.do
sed -i s'/asim +access +r/eval asim $SIM_OPT/' ./riviera/design_1_wrapper_simulate.do
sed -i '17,$d' ./riviera/design_1_wrapper_simulate.do
sed -i s'/xil_defaultlib.glbl/xil_defaultlib.glbl \\\
-g$GENERIC_PATH=$env(RPORT_PATH_HDL) -g$QUANTUM_GENERIC_PATH=$env(SYNC_QUANTUM) \n \
run -all/' ./riviera/design_1_wrapper_simulate.do


# do poprawienia skrypt i wrappery vhd SC
python3 ./scripts/generate_sim_files.py  hardware/reference_project/reference_project.gen/sources_1/bd/design_1/ip/design_1_zynq_ultra_ps_e_0_0/design_1_zynq_ultra_ps_e_0_0_stub.vhdl riviera/
