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
#       |-- B.x
#       |-- B.y
#
# In a tree, this looks like:
#
#   {A clk reset {B x y}}
#
# Thereby the first entry in a list is the module name and everything
# else is the module body (c.f., Lisp `car` and `cdr`). A signal is a
# list with size == 1 while a module is a list with size > 1.

#--------------------------------------- New procedures for addWavesRecursive
# Given a raw VCD signal, construct a tree out of this.
proc constructTree {signal} {
    foreach node [lreverse [string map {. " "} $signal]] {
        if {[info exists tree]} {
            set tree [list $node $tree]
        } else {
            set tree $node
        }
    }
    return $tree
}

# Attaches a linear subtree to an existing tree. The tree and subtree
# must have the same root node. This function looks at all the
# children of both the tree and the subtree and recurses if it finds a
# matching child. If it doesn't find a matching child, it will append
# the subtree to the current node.
proc merge {tree subtree} {
    set index 1
    set newtree {}
    foreach child [lrange $tree 1 end] {
        foreach subchild [lrange $subtree 1 end] {
            # If we find a match, then we recurse
            if {[string compare [lindex $child 0] [lindex $subchild 0]] == 0} {
                return [lreplace $tree $index $index [merge $child $subchild]]
            }
        }
        incr index
    }
    # We didn't find anything so we just append this list
    lappend tree [lindex $subtree 1]
    return $tree
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
proc gtkwaveEmitModule {tree prefix} {
    set car [lindex $tree 0]
    set cdr [lrange $tree 1 end]
    gtkwaveEnterModule $prefix$car
    puts "\[*\] MODULE: $prefix$car"
    foreach signal $cdr {
        if {[llength $signal] > 1} {
            gtkwaveEmitModule $signal "$prefix$car."
        } else {
            puts "$prefix$car.$signal"
        }
    }
    gtkwaveExitModule $prefix$car
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

# Get a list of all the signals in the design
set signals [list]
for {set i 0} {$i < $nfacs } {incr i} {
    set facname [ gtkwave::getFacName $i ]
    lappend signals "$facname"
}

# Initialize a singal node tree with the top module
set tree [lindex [split [lindex $signals 0] .] 0]

# Append each of the signals to the tree. [TODO] Possibly a source of
# slowdown.
foreach signal $signals {
    set tree [merge $tree [constructTree $signal]]
}

# Walk the tree emitting a .gtkw file describing the hierarchy
gtkwaveEmitModule $tree ""

# We're done, so exit.
gtkwave::/File/Quit
