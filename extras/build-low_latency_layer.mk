##
## low_latency_layer (EX-Proton)
##
## Vulkan layer from Korthos-Software/low_latency_layer, enabled at run time
## with LOW_LATENCY_LAYER=1. Build rules follow Proton-GE's
## vklayers/build-low_latency_layer.mk and build-vulkan-utility-libraries.mk.
## Only built when the source trees are present (scripts/prepare.sh clones
## them from extras.conf).
##
## Vulkan-Utility-Libraries needs newer Vulkan headers than the base's
## Vulkan-Headers pin, so the layer is built against its own copy
## (extras/Vulkan-Headers-layer); the base's headers are left alone.

ifneq ($(wildcard $(SRC)/extras/low_latency_layer/CMakeLists.txt),)
ifneq ($(wildcard $(SRC)/extras/Vulkan-Utility-Libraries/CMakeLists.txt),)
ifneq ($(wildcard $(SRC)/extras/Vulkan-Headers-layer/CMakeLists.txt),)

$(eval $(call rules-source,vulkan-headers-layer,$(SRCDIR)/extras/Vulkan-Headers-layer))
$(eval $(call rules-cmake,vulkan-headers-layer,x86_64,unix))
$(eval $(call rules-cmake,vulkan-headers-layer,aarch64,unix))

## Build-time only; it is not shipped.
$(OBJ)/.vulkan-headers-layer-x86_64-dist:
	touch $@
$(OBJ)/.vulkan-headers-layer-aarch64-dist:
	touch $@

VULKAN_UTILITY_LIBRARIES_CMAKE_ARGS = \
  -DCMAKE_BUILD_TYPE=release

VULKAN_UTILITY_LIBRARIES_DEPENDS = vulkan-headers-layer

$(eval $(call rules-source,vulkan-utility-libraries,$(SRCDIR)/extras/Vulkan-Utility-Libraries))
$(eval $(call rules-cmake,vulkan-utility-libraries,x86_64,unix))
$(eval $(call rules-cmake,vulkan-utility-libraries,aarch64,unix))

## Only used to build low_latency_layer; it is not shipped.
$(OBJ)/.vulkan-utility-libraries-x86_64-dist:
	touch $@
$(OBJ)/.vulkan-utility-libraries-aarch64-dist:
	touch $@

LOW_LATENCY_LAYER_CMAKE_ARGS = \
  -DCMAKE_BUILD_TYPE=release

LOW_LATENCY_LAYER_DEPENDS = vulkan-headers-layer vulkan-utility-libraries

$(eval $(call rules-source,low_latency_layer,$(SRCDIR)/extras/low_latency_layer))
$(eval $(call rules-cmake,low_latency_layer,x86_64,unix))
$(eval $(call rules-cmake,low_latency_layer,aarch64,unix))

$(OBJ)/.low_latency_layer-x86_64-post-build:
	mkdir -p $(DST_DIR)/share/low_latency_layer/implicit_layer.d/
	cp -a $(LOW_LATENCY_LAYER_x86_64_DST)/share/vulkan/implicit_layer.d/low_latency_layer.json $(DST_DIR)/share/low_latency_layer/implicit_layer.d/
	touch $@

$(OBJ)/.low_latency_layer-aarch64-post-build:
	mkdir -p $(DST_DIR)/share/low_latency_layer/implicit_layer.d/
	cp -a $(LOW_LATENCY_LAYER_aarch64_DST)/share/vulkan/implicit_layer.d/low_latency_layer.json $(DST_DIR)/share/low_latency_layer/implicit_layer.d/
	touch $@

all-dist: low_latency_layer

endif # extras/Vulkan-Headers-layer present
endif # extras/Vulkan-Utility-Libraries present
endif # extras/low_latency_layer present
