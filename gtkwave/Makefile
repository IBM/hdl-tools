PREFIX ?= $(abspath ../opt)

.PHONY: all install
all: install

$(PREFIX)/bin/gtkwave: | repo
	@echo "[INFO] Building GTKWave"
	(cd repo && \
	./configure --prefix=$(PREFIX) && \
	make -j$(JOBS) install || true) | tee build.log

repo:
	svn co "svn://svn.code.sf.net/p/gtkwave/code/gtkwave3" $@
