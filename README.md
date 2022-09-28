# QEMU-MPA

## Running example

1. Change directory to `TySOM-2-7Z100` or `TySOM-3-ZU7`:

   ```sh
   cd TySOM-2-7Z100 
   ```
   or
   ```sh
   cd TySOM-3-ZU7 
   ```

2. Set paths to tools (Vivado, PetaLinux, Riviera-Pro) in `config.sh`.

3. Set the proper option of line-ends conversion for used git application

   ```   
   git config --global core.autocrlf input
   ```

4. Prepare example by running the script:

   ```sh
   ./prepare_hardware.sh
   ./prepare_linux.sh
   ./prepare_sim_files.sh
   ```

5. Start the example:

   ```sh
   ./run_example_cosim.sh
   ```

6. After starting the example using previous steps, add waveform in Riviera, by
   typing the following command in its console:

   ```sh
   wave sim:/design_1_wrapper/design_1_i/core_0/*
   ```
### Simulation without GDB
7. After Linux prompt shows up in QEMU use following commands:

   ```sh
   cd /home/patalinux/pgmpa
   ./pgmpa powernn/powernn_100
   ```
### Debugging with GDB

7.1. After Linux prompt shows up in QEMU, start GDB using commands:

   ```sh
   cd /home/patalinux/pgmpa
   gdb --args ./pgmpa powernn/powernn_100
   ```

7.2. Once GDB finishes loading, insert a breakpoint. For example, let's place
   breakpoint at the end of the register clearing loop:

   ```gdb
   break 144
   ```

7.3. Now, run the program:

   ```gdb
   run
   ```

7.4. The program should print names of the cleared registers and stop at the
   breakpoint. Switch to Riviera and pause the simulation using the "STOP"
   button or the Ctrl+Shift+C key combination. This should generate the waveform
   of the operation.

   **NOTE** Until the the simulation is resumed, Linux running inside QEMU will
   be frozen and keyboard input will not be processed.

7.5. Press the green "play" button in Riviera, or press the Shift+F5 key combination to
   resume the simulation. Switch to the QEMU window again continue running the
   program:

   ```gdb
   continue
   ```
###
8.   When `Finish PROG` appears on the screen, press any key. The program should
   print the result and finish. On the waveform in Riviera, `m00_axis_tdata`
   port should now display the transferred data.
