# TCL srcipt that uses the TCL-enabled version of GTKWave to generate
# a .gtkw save file with all the signals and groups found in a .vcd
# file. You will need to have the TCL enabled version of GTKWave
# installed to use this, e.g.:
#
#   yaourt -S gtkwave-tcl-svn
#
# Usage (run this to generate the .gtkw, then open it in GTKWave):
#   gtkwave -S addWavesRecursive.tcl [VCD FILE] > [GTKW FILE]
#   gtkwave [VCD FILE] [GTKW FILE]
#-------------------------------------------------------------------------------
# Contact point: Schuyler Eldridge <schuyler.eldridge@ibm.com>
#
# Copyright (C) 2016 IBM
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------

#--------------------------------------- VCD file as a tree
# Here, we're dealing with a data structure to describe a tree that
# consists of nested lists. So, assume that we have the following HDL
# structure as can be gleaned from looking at all the nodes in a VCD
# file:
#
#   A
#   |-- A.clk
#   |-- A.reset
#   |-- B
#   |   |-- B.x
#   |   \-- B.y
#   \-- C
#
# In a tree, this looks like:
#
#   {A clk reset {B x y} C}
#
# Thereby the first entry in a list is the module name and everything
# else is the module body (c.f., Lisp `car` and `cdr`). A signal is a
# list with size == 1 while a module is a list with size > 1.
proc car x { lindex $x 0 }
proc cdr x { lrange $x 1 end }

#--------------------------------------- New procedures for addWavesRecursive
# Given a raw VCD signal, construct a tree out of this.
proc constructTree {signal} {
    set tmp [lreverse [string map {. " "} $signal]]
    set tree [car $tmp]
    foreach node [cdr $tmp]  {
        set tree [list $node $tree]
    }
    return $tree
}

# Merges two lexicographically sorted trees.
proc merge_slow {a b} {
    set a_i 1
    set b_i 1
    while {($a_i < [llength $a]) || ($b_i < [llength $b])} {
        set x [lindex $a $a_i]
        set y [lindex $b $b_i]

        switch [string compare [car $x] [car $y]] {
            -1 {if {$a_i >= [llength $a] - 1} { break }
                incr a_i }
            1  {if {$b_i >= [llength $b] - 1} { break }
                incr b_i }
            0  {return [lreplace $a $a_i $a_i [merge_slow $x $y]] }
        }
    }
    return [lappend a [lindex $b 1]]
}

# Merges a bushy tree (branching factor >= 1) 'a' with all nodes at
# the same depth lexicographically sorted with a slim tree (branching
# factor == 1), 'b'. This compares, at the same depth, the last node
# in the 'a' with the (only) node in 'b'. If these are the same, then
# we recurse one layer deeper in 'a' and 'b'. Otherwise, 'b' is a new
# branch that should be appended at this depth to 'a'.
proc merge_fast {a b} {
    set a_i [expr {[llength $a] - 1}]
    set b_i 1

    set x [lindex $a $a_i]
    set y [lindex $b $b_i]

    if { [string compare [car $x] [car $y]] } {
        return [lappend a [lindex $b 1]]
    }

    return [lreplace $a $a_i $a_i [merge_fast $x $y]]
}

# GTKWave uses some special bit flags to tell it what type of signal
# we're dealing with. This is all documented internally in their
# "analyzer.h" file. However, all that we really care about are:
#
#        0x22: (right justified) | (hexadecimal format)
#        0x28: (right justified) | (binary format)
#    0xc00200: (group state)     | (TR_CLOSED_B)        | (TR_BLANK)
#   0x1401200: (group end)       | (TR_CLOSED_B)        | (TR_BLANK)
#
# Whenever we see a group, we need to explicitly set these before the
# group name. After the group, we need to revert to the default signal
# format 0x22 (or 0x28). We set the groups as closed because this
# seems to make the initial signal dump easier to look at.
# alternatively, the following group bits can be used to have the
# groups default to open:
#
#    0x800200: (group start)     | (TR_BLANK)
#   0x1000200: (group end)       | (TR_BLANK)
proc gtkwaveEnterModule {module} {
    puts "\[*\]vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    puts "@c00200"
    puts "-$module"
    puts "@22"
}
proc gtkwaveExitModule {module} {
    puts "@1401200"
    puts "-$module"
    puts "@22"
    puts "\[*\]^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
}

# Walk a tree or emitting the enter/exit module GTK boilerplate
# whenever we hit a module.
proc gtkwaveEmitModule {tree prefix spacing} {
    set car [car $tree]
    set cdr [cdr $tree]
    gtkwaveEnterModule $car
    # puts stderr "\[INFO\]  $spacing$car"
    puts "\[*\] MODULE: $prefix$car"
    foreach signal $cdr {
        if {[llength $signal] > 1} {
            gtkwaveEmitModule $signal "$prefix$car." "  $spacing"
        } else {
            puts "$prefix$car.$signal"
        }
    }
    gtkwaveExitModule $car
}

#---------------------------------------- Main addWavesRecursive TCL script
set nfacs    [ gtkwave::getNumFacs      ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt      [ gtkwave::getDumpType     ]

# Some information is included in the GTKWave header, however this
# doesn't appear to have much effect on GTKWave. Generally, GTKWave
# will just ignore things it doesn't understand. Nevertheless, we
# default to using a coment syntax of "[*]":
# puts "\[*\] number of signals in dumpfile '$dumpname' of type $dmt: $nfacs"
# puts "\[dumpfile\] \"[file join [pwd] $dumpname]\""
# puts "\[dumpfile_size\] [file size [file join [pwd] $dumpname]]"
# puts "\[optimize_vcd\]"
# A .gtkw file has some additional meta information which we're not
# using:
# puts "\[savefile\]"
# puts "\[timestart\] 0"

# Get a list of all the signals in the design that are not "generated"
# or "temporary".
puts stderr "\[INFO\] Reading all signals in design"
set signals [list]
for {set i 0} {$i < $nfacs } {incr i} {
    set facname [ gtkwave::getFacName $i ]
    if {![regexp {^.*\.(GEN|T)_.*} $facname]} {
        lappend signals "$facname"
    }
}
puts stderr "\[INFO\]   Found [llength $signals]"

# Initialize a single node tree with the top module. Append each of
# the signals to the tree. [TODO] Possibly a source of slowdown.
puts stderr "\[INFO\] Construcing Trees"
set trees [list]
foreach signal $signals {
    lappend trees [constructTree $signal]
}

puts stderr "\[INFO\] Merging Trees"
set tree [lindex [split [car $signals] .] 0]
foreach signal $trees {
    set tree [merge_fast $tree $signal]
}

# Walk the tree emitting a .gtkw file describing the hierarchy
puts stderr "\[INFO\] Emitting modules"
gtkwaveEmitModule $tree "" ""

# We're done, so exit.
gtkwave::/File/Quit
