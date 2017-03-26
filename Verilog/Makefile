PREFIX ?= $(abspath ../opt)

.PHONY: all

all: $(PREFIX)/lib/perl5/x86_64-linux-gnu-thread-multi/Verilog/Netlist.pm

install:
$(PREFIX)/lib/perl5/x86_64-linux-gnu-thread-multi/Verilog/Netlist.pm: | repo/.git
	@echo "[INFO] Building Verilog::Perl"
	(cd repo && \
	perl Makefile.PL INSTALL_BASE=$(PREFIX) && \
	make JOBS=$(JOBS) && \
	make install JOBS=$(JOBS)) 2>&1 | tee build.log

repo/.git:
	git submodule update --init repo

mrproper:
	rm -rf repo && git checkout repo
