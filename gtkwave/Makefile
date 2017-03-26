PREFIX ?= $(abspath ../opt)

.PHONY: all

all: $(PREFIX)/bin/gtkwave

install:
$(PREFIX)/bin/gtkwave: | repo
	@echo "[INFO] Building GTKWave"
	(cd repo && \
	./configure --prefix=$(PREFIX) && \
	make -j$(JOBS) install || true) 2>&1 | tee build.log

repo:
	svn co "svn://svn.code.sf.net/p/gtkwave/code/gtkwave3" $@

mrproper:
	rm -rf repo
