HDL Tools [![Build Status](https://travis-ci.org/IBM/hdl-tools.svg?branch=master)](https://travis-ci.org/IBM/hdl-tools)
=====================

Environment for working with HDLs. This builds a number of tools from source and relies on some scripts to facilitate HDL work.

## Programs
All the programs are fetched (as a `git` submodule, via `svn`, or as a direct download) and built. You can do this with the included [Makefile](Makefile) targets for individual tools:
* `verilator` -- Build Verilator
* `gtkwave` -- Build GTKWave

Additional targets include:
* `build-all` -- Build all the tools
* `usage` -- list all available build targets
* `clean-installed` -- remove the installed tools in `./opt/` (__this will not respect `PREFIX` so that you don't nuke your /opt directory__)
* `clean-downloaded` -- remove all downloaded program sources
* `mrproper` -- remove downloaded program contents

Tools will, by default, be installed in `./opt/`. However, you can pass a `PREFIX` option to the Makefile if for whatever reason you want to install these somewhere else (not advised).

#### [Verilator](http://www.veripool.org/wiki/verilator)
Verilog to C++ compiler. This is not required to be built for working with Rocket Chip (it will build its own version of Verilator).

#### [GTKWave](http://gtkwave.sourceforge.net/)
Open source (GPL2) waveform viewer with TCL integration.

#### [Verilog::Perl](http://www.veripool.org/wiki/verilog-perl)
Perl tools for working with Verilog netlists.

## Scripts

#### [`addWavesRecursive.tcl`](scripts/addWavesRecursive.tcl)
TCL script that, when passed to GTKWave, will generate a saved waveform view (a .gtkw file) that has all the signals in a given VCD file grouped by module. An example invocation would be:

```
gtkwave -S addWavesRecursive.tcl dump.vcd > dump.gtkw
```

You can then start GTKWave using this saved view with:

```
gtkwave dump.vcd dump.gtkw
```

After 904555632a5131686c20921593ba7010efece916, this is `O(n log n)` in the number of signals. Previously, this was `O(n^2)`.

#### [`vcd-prune`](scripts/vcd-prune)
Perl script to prune a VCD file to only include specific modules (and all their submodules. An example invocation would be:

```
./vcd-prune dump.vcd -m MyModule -o dump-short.vcd
```

This will only dump signals contained in MyModule or its submodules. For testing a small part of a huge design (e.g., a RoCC unit attached to Rocket Chip), this can cut down dramatically on the size of the VCD file and the processing time of `addWavesRecursive.tcl` and startup time of a waveform viewer.

* [`Verilator`](http://www.veripool.org/wiki/verilator) -- Verilog to C++ compiler
* [`GTKWave`](http://gtkwave.sourceforge.net) -- Lightweight waveform viewer
* `scripts/`
  * [`addWavesRecursive.tcl`](scripts/addWavesRecursive.tcl) -- TCL script for GTKWave that populates the waveform viewer with signals nested into the module hierarchy

#### [`gtkwave-helper`](scripts/gtkwave-helper)
Bash script that takes care of the boilerplate operations necessary to launch GTKWavewith `addWavesRecursive`.

#### Complexities
This comes up as these tools are intended to be used on large amounts of data

| Tool                                                     | Complexity     | What is N?        | Critical Region                                 |
| -------------                                            | -------------: | -----:            | --------------:                                 |
| [`addWavesRecursive.tcl`](scripts/addWavesRecursive.tcl) | n log n        | number of signals | [tree merge](scripts/addWavesRecursive.tcl#L89) |
| [`vcd-prune`](scripts/vcd-prune)                         | n              | number of lines   | [regex](scripts/vcd-prune#L112)                 |
| [`gtkwave-helper`](scripts/gtkwave-helper)               |                |                   |                                                 |
