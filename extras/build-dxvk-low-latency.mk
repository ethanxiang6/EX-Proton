##
## dxvk-low-latency (EX-Proton)
##
## Optional second DXVK build from netborg-afps/dxvk-low-latency, installed
## beside the stock DXVK and selected at run time with PROTON_DXVK_LOWLATENCY=1.
## Build rules mirror the stock dxvk rules in Makefile.in; the side-by-side
## layout follows proton-cachyos' extras/build-dxvk-low-latency.mk.
## Only built when the source tree is present (scripts/prepare.sh clones it
## from extras.conf).

ifneq ($(wildcard $(SRC)/extras/dxvk-low-latency/meson.build),)

# wine builds DLLs with the same names, we need to differentiate the timestamps
DXVK_LOW_LATENCY_i386_SOURCE_DATE_EPOCH := $(shell expr $(i386_SOURCE_DATE_EPOCH) - 3)
DXVK_LOW_LATENCY_x86_64_SOURCE_DATE_EPOCH := $(shell expr $(x86_64_SOURCE_DATE_EPOCH) - 3)
DXVK_LOW_LATENCY_arm64ec_SOURCE_DATE_EPOCH := $(shell expr $(arm64ec_SOURCE_DATE_EPOCH) - 3)

DXVK_LOW_LATENCY_SOURCE_ARGS = \
  --exclude version.h.in \

DXVK_LOW_LATENCY_arm64ec_CFLAGS = -marm64x
DXVK_LOW_LATENCY_arm64ec_LDFLAGS = -marm64x

DXVK_LOW_LATENCY_i386_MESON_ARGS = --bindir=$(DXVK_LOW_LATENCY_i386_DST)/lib/wine/dxvk-low-latency/i386-windows
DXVK_LOW_LATENCY_x86_64_MESON_ARGS = --bindir=$(DXVK_LOW_LATENCY_x86_64_DST)/lib/wine/dxvk-low-latency/x86_64-windows
DXVK_LOW_LATENCY_arm64ec_MESON_ARGS = --bindir=$(DXVK_LOW_LATENCY_arm64ec_DST)/lib/wine/dxvk-low-latency/aarch64-windows
DXVK_LOW_LATENCY_HOST_DEPENDS = glslang

$(eval $(call rules-source,dxvk-low-latency,$(SRC)/extras/dxvk-low-latency))
$(eval $(call rules-meson,dxvk-low-latency,i386,windows))
$(eval $(call rules-meson,dxvk-low-latency,x86_64,windows))
$(eval $(call rules-meson,dxvk-low-latency,arm64ec,windows))

$(OBJ)/.dxvk-low-latency-post-source:
	sed -re 's#@VCS_TAG@#$(shell git -C $(SRC)/extras/dxvk-low-latency describe --always --abbrev=15 --dirty=0 || echo deadbeef)-low-latency#' \
	    $(SRC)/extras/dxvk-low-latency/version.h.in > $(DXVK_LOW_LATENCY_SRC)/version.h.in
	mkdir -p $(DST_LIBDIR)/wine/dxvk-low-latency
	rm -rf $(DST_LIBDIR)/wine/dxvk-low-latency/version
	echo "$(shell git -C $(SRC)/extras/dxvk-low-latency rev-parse HEAD 2>/dev/null || echo no-git-repo-info)" > $(DST_LIBDIR)/wine/dxvk-low-latency/version
	touch $@

default_pfx: dxvk-low-latency

endif # extras/dxvk-low-latency present
