Environment for working with HDLs. This builds a number of tools from source and relies on some scripts to facilitate HDL work.

## Tools
* [`Verilator`](http://www.veripool.org/wiki/verilator) -- Verilog to C++ compiler
* [`GTKWave`](http://gtkwave.sourceforge.net) -- Lightweight waveform viewer
* `scripts/`
  * [`addWavesRecursive.tcl`](scripts/addWavesRecursive) -- TCL script for GTKWave that populates the waveform viewer with signals nested into the module hierarchy
