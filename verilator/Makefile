PREFIX ?= $(abspath ../opt)

.PHONY: install

$(PREFIX)/bin/verilator: | repo/.git
	@echo "[INFO] Building Verilator"
	@echo "[INFO] Verilator uses a lot of memory to build, limiting jobs to 2"
	(cd repo && \
	autoconf && \
	./configure --prefix=$(PREFIX) && \
	make -j2 install) 2>&1 | tee build.log

repo/.git:
	git submodule update --init repo

clean:
	@(cd repo && make clean) >> build.log

mrproper:
	rm -rf repo
