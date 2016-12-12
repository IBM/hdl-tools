base_dir = $(abspath .)

PREFIX ?= $(base_dir)/opt
JOBS ?= 8

tools = \
	verilator \
	gtkwave
perl_libs = \
	Verilog

.PHONY: all build-all default gtkwave usage verilator

default: usage

usage:           ## show this help
	@echo "Usage: make [target]\nBuild HDL tools in PREFIX (default: $(PREFIX))\n\nOptions:"
	@grep "##" $(MAKEFILE_LIST) | grep -v "#.ignore" | sed 's/^/  /' | sed 's/:.\+##/,/' | column -s, -n -t #.ignore

build-all: $(tools:%=$(PREFIX)/bin/%) $(PREFIX)/lib/perl5/x86_64-linux-gnu-thread-multi/Verilog/Netlist.pm ## build all tools
verilator: $(PREFIX)/bin/verilator ## build verilator
gtkwave: $(PREFIX)/bin/gtkwave ## build gtkwave
verilog-perl: $(PREFIX)/lib/perl5/x86_64-linux-gnu-thread-multi/Verilog/Netlist.pm ## build Verilog::Perl

$(PREFIX)/bin/%:
	$(MAKE) -C $(base_dir)/$* PREFIX=$(PREFIX) JOBS=$(JOBS) $@
$(PREFIX)/lib/perl5/x86_64-linux-gnu-thread-multi/Verilog/Netlist.pm:
	$(MAKE) -C $(base_dir)/Verilog PREFIX=$(PREFIX) JOBS=$(JOBS) $@

clean-installed: ## remove the installed tools in ./opt
	rm -rf $(base_dir)/opt

clean-downloaded: ## blow away program source directories
	rm -rf $(base_dir)/verilator/repo
	rm -rf $(base_dir)/gtkwave/repo

mrproper: clean-installed clean-downloaded ## remote tools and blow away download sources
