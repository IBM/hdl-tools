## GTKWave

### addWavesRecursive

GTKWave is awesome, but I hate adding waves and grouping them
manually. Enter
[addWavesRecursive.tcl](https://github.com/seldridge/hdl-scripts/blob/master/addWavesRecursive.tcl)
which will analyze a VCD file and populate a .gtkw file (a saved
GTKWave configuration) with all signals arranged in their respective
modules. Hierarchy is preserved.

How does this work?

Using some TCL for dealing with trees from Richard Suchenwirth and
some custom procedures, I treat each signal in the VCD as a bare tree
that doesn't diverge at any level (basically a linked list). I then
merge all these individual trees into one large tree. Finally, I
traverse the tree and generate group markers whenever I cross a module
boundary.
