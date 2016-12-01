base_dir = $(abspath .)

PREFIX ?= $(base_dir)/opt
JOBS ?= 8

tools = \
	verilator \
	gtkwave

.PHONY: all build-all default gtkwave usage verilator

default: usage

usage:           ## show this help
	@echo "Usage: make [target]\nBuild HDL tools in PREFIX (default: $(PREFIX))\n\nOptions:"
	@grep "##" $(MAKEFILE_LIST) | grep -v "#.ignore" | sed 's/^/  /' | sed 's/:.\+##/,/' | column -s, -n -t #.ignore

build-all: $(tools:%=$(PREFIX)/bin/%) ## build all tools
verilator: $(PREFIX)/bin/verilator ## build verilator
gtkwave: $(PREFIX)/bin/gtkwave ## build gtkwave

$(PREFIX)/bin/%:
	$(MAKE) -C $(base_dir)/$* PREFIX=$(PREFIX) JOBS=$(JOBS) $@

clean:
	rm -rf $(PREFIX)

mrproper: clean
	rm -rf $(base_dir)/verilator/repo
	rm -rf $(base_dir)/gtkwave/repo
