##
## vkd3d-low-latency (EX-Proton)
##
## Optional second vkd3d-proton build from netborg-afps/vkd3d-low-latency,
## installed beside the stock vkd3d-proton and selected at run time with
## PROTON_VKD3D_LOWLATENCY=1. Build rules mirror the stock vkd3d-proton rules
## in Makefile.in; the side-by-side layout follows proton-cachyos'
## extras/build-vkd3d-low-latency.mk.
## Only built when the source tree is present (scripts/prepare.sh clones it
## from extras.conf).

ifneq ($(wildcard $(SRC)/extras/vkd3d-low-latency/meson.build),)

# wine builds DLLs with the same names, we need to differentiate the timestamps
VKD3D_LOW_LATENCY_i386_SOURCE_DATE_EPOCH := $(shell expr $(i386_SOURCE_DATE_EPOCH) - 4)
VKD3D_LOW_LATENCY_x86_64_SOURCE_DATE_EPOCH := $(shell expr $(x86_64_SOURCE_DATE_EPOCH) - 4)
VKD3D_LOW_LATENCY_arm64ec_SOURCE_DATE_EPOCH := $(shell expr $(arm64ec_SOURCE_DATE_EPOCH) - 4)

VKD3D_LOW_LATENCY_SOURCE_ARGS = \
  --exclude vkd3d_build.h.in \
  --exclude vkd3d_version.h.in \

VKD3D_LOW_LATENCY_MESON_ARGS = -Db_ndebug=true -Denable_extended_emulation=true
VKD3D_LOW_LATENCY_i386_MESON_ARGS = --bindir=$(VKD3D_LOW_LATENCY_i386_DST)/lib/wine/vkd3d-low-latency/i386-windows
VKD3D_LOW_LATENCY_x86_64_MESON_ARGS = --bindir=$(VKD3D_LOW_LATENCY_x86_64_DST)/lib/wine/vkd3d-low-latency/x86_64-windows
VKD3D_LOW_LATENCY_arm64ec_MESON_ARGS = --bindir=$(VKD3D_LOW_LATENCY_arm64ec_DST)/lib/wine/vkd3d-low-latency/aarch64-windows
VKD3D_LOW_LATENCY_HOST_DEPENDS = glslang

VKD3D_LOW_LATENCY_arm64ec_CFLAGS = -marm64x
VKD3D_LOW_LATENCY_arm64ec_LDFLAGS = -marm64x

ifneq ($(UNSTRIPPED_BUILD),)
	VKD3D_LOW_LATENCY_MESON_ARGS = -Denable_trace=true
endif

$(eval $(call rules-source,vkd3d-low-latency,$(SRC)/extras/vkd3d-low-latency))
$(eval $(call rules-meson,vkd3d-low-latency,i386,windows))
$(eval $(call rules-meson,vkd3d-low-latency,x86_64,windows))
$(eval $(call rules-meson,vkd3d-low-latency,arm64ec,windows))

$(OBJ)/.vkd3d-low-latency-post-source:
	sed -re 's#@VCS_TAG@#$(shell git -C $(SRC)/extras/vkd3d-low-latency describe --always --exclude=* --abbrev=15 --dirty=0 || echo deadbeef)#' \
	    $(SRC)/extras/vkd3d-low-latency/vkd3d_build.h.in > $(VKD3D_LOW_LATENCY_SRC)/vkd3d_build.h.in
	sed -re 's#@VCS_TAG@#$(shell git -C $(SRC)/extras/vkd3d-low-latency describe --always --tags --dirty=+ || echo deadbeef)-low-latency#' \
	    $(SRC)/extras/vkd3d-low-latency/vkd3d_version.h.in > $(VKD3D_LOW_LATENCY_SRC)/vkd3d_version.h.in
	mkdir -p $(DST_LIBDIR)/wine/vkd3d-low-latency
	rm -rf $(DST_LIBDIR)/wine/vkd3d-low-latency/version
	echo "$(shell git -C $(SRC)/extras/vkd3d-low-latency rev-parse HEAD 2>/dev/null || echo no-git-repo-info)" > $(DST_LIBDIR)/wine/vkd3d-low-latency/version
	touch $@

default_pfx: vkd3d-low-latency

endif # extras/vkd3d-low-latency present
