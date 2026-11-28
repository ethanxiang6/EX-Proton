##
## discord-rpc-bridge (EX-Proton)
##
## enderice2/rpc-bridge (MIT): a small Windows program that forwards a game's
## Discord Rich Presence pipe (\.\pipe\discord-ipc-0) to the native Linux
## Discord client's socket, so Discord can show what is being played. Build
## rules follow Proton-GE's. x86-64 only: the bridge issues raw x86-64 Linux
## system calls, which do not work from translated code on ARM64.
## Installed to lib/wine/discord-rpc-bridge/; the launcher copies it into the
## prefix and steam.exe registers and starts it as a Wine service.

ifneq ($(wildcard $(SRC)/extras/discord-rpc-bridge/src/Makefile),)

$(eval $(call rules-source,discord-rpc-bridge,$(SRCDIR)/extras/discord-rpc-bridge))
$(eval $(call create-rules-common,discord-rpc-bridge,DISCORD_RPC_BRIDGE,x86_64,unix))
$(eval $(call create-rules-common,discord-rpc-bridge,DISCORD_RPC_BRIDGE,aarch64,unix))

$(OBJ)/.discord-rpc-bridge-x86_64-build:
	@echo ":: building discord-rpc-bridge-x86_64..." >&2
	rsync -arx "$(DISCORD_RPC_BRIDGE_SRC)/" "$(DISCORD_RPC_BRIDGE_x86_64_OBJ)/"
	mkdir -p "$(DISCORD_RPC_BRIDGE_x86_64_OBJ)/build"
	env $(DISCORD_RPC_BRIDGE_x86_64_ENV) \
	    $(MAKE) -C "$(DISCORD_RPC_BRIDGE_x86_64_OBJ)" build
	touch $@

$(OBJ)/.discord-rpc-bridge-x86_64-post-build:
	mkdir -p $(DISCORD_RPC_BRIDGE_x86_64_DST)/lib/wine/discord-rpc-bridge
	cp $(DISCORD_RPC_BRIDGE_x86_64_OBJ)/build/bridge.exe $(DISCORD_RPC_BRIDGE_x86_64_DST)/lib/wine/discord-rpc-bridge/
	touch $@

$(OBJ)/.discord-rpc-bridge-aarch64-build:
	touch $@

$(OBJ)/.discord-rpc-bridge-aarch64-post-build:
	touch $@

$(OBJ)/.discord-rpc-bridge-aarch64-dist:
	touch $@

default_pfx: discord-rpc-bridge

endif # extras/discord-rpc-bridge present
