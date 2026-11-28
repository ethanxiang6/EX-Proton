##
## protonfixes (EX-Proton)
##
## open-wine-components/umu-protonfixes: per-game fixes and the upscaler
## (FSR4) download helper, installed as <build>/protonfixes and imported by
## the launcher script. Build rules follow Proton-GE's Makefile.in.
## Only built when the source tree is present (scripts/prepare.sh clones it
## from extras.conf).

ifneq ($(wildcard $(SRC)/extras/protonfixes/Makefile),)

$(eval $(call rules-source,protonfixes,$(SRCDIR)/extras/protonfixes))
$(eval $(call rules-common,protonfixes,x86_64,unix))
$(eval $(call rules-common,protonfixes,aarch64,unix))

$(OBJ)/.protonfixes-x86_64-build:
	cd $(PROTONFIXES_SRC) && \
	env $(PROTONFIXES_x86_64_ENV) BUILD=$(PROTONFIXES_x86_64_OBJ) TARGET_ARCH=$(TARGET_ARCH) make
	cd $(PROTONFIXES_SRC) && \
	env $(PROTONFIXES_x86_64_ENV) BUILD=$(PROTONFIXES_x86_64_OBJ) DIST=$(PROTONFIXES_x86_64_DST) TARGET_ARCH=$(TARGET_ARCH) make install
	touch $@

$(OBJ)/.protonfixes-aarch64-build:
	cd $(PROTONFIXES_SRC) && \
	env $(PROTONFIXES_aarch64_ENV) BUILD=$(PROTONFIXES_aarch64_OBJ) TARGET_ARCH=$(TARGET_ARCH) make
	cd $(PROTONFIXES_SRC) && \
	env $(PROTONFIXES_aarch64_ENV) BUILD=$(PROTONFIXES_aarch64_OBJ) DIST=$(PROTONFIXES_aarch64_DST) TARGET_ARCH=$(TARGET_ARCH) make install
	touch $@

PROTONFIXES_TARGET := $(addprefix $(DST_BASE)/,protonfixes)

$(OBJ)/.protonfixes-x86_64-dist:
	mkdir -p $(PROTONFIXES_TARGET)
	rsync --delete -arx $(PROTONFIXES_x86_64_DST)/ $(PROTONFIXES_TARGET)
	touch $@

$(OBJ)/.protonfixes-aarch64-dist:
	mkdir -p $(PROTONFIXES_TARGET)
	rsync --delete -arx $(PROTONFIXES_aarch64_DST)/ $(PROTONFIXES_TARGET)
	touch $@

all-dist: protonfixes

endif # extras/protonfixes present
