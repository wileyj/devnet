ifeq (log,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
ifeq (pause,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
ifeq (resume,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
## UID and GID are not currently used, but will be in the near future
export UID := $(shell getent passwd $$(whoami) | cut -d":" -f 3)
export GID := $(shell getent passwd $$(whoami) | cut -d":" -f 4)
EPOCH := $(shell date +%s)
PWD = $(shell pwd)
CHAINSTATE_ARCHIVE ?= $(PWD)/docker/chainstate.tar.zstd
export CHAINSTATE_DIR ?= $(PWD)/docker/chainstate/$(EPOCH)
export DOCKER_NETWORK ?= stacks
SERVICES := $(shell CHAINSTATE_DIR="" docker compose -f docker/docker-compose.yml --profile=default config --services)
PAUSE_HEIGHT ?= 999999999999

$(CHAINSTATE_DIR):
	@echo "Creating Chainstate Dir ($(CHAINSTATE_DIR))"
	mkdir -p $@
	if [ -f "$(CHAINSTATE_ARCHIVE)" -a "$(MAKECMDGOALS)" = "up" ]; then
		sudo tar --same-owner -xf $(CHAINSTATE_ARCHIVE) -C $(CHAINSTATE_DIR) || false
		sudo rm -rf $(CHAINSTATE_DIR)/stacks-signer*
	fi

check-network-running:
	@if [ -f .current-chainstate-dir ]; then \
		echo ""; \
		echo "WARNING: Network appears to be running or was not properly shut down."; \
		echo "Current chainstate directory: $$(cat .current-chainstate-dir)"; \
		echo ""; \
		echo "To backup logs first: make backup-logs"; \
		echo "To shut down:         make down"; \
		echo ""; \
		exit 1; \
	fi

up: check-network-running build | $(CHAINSTATE_DIR)
	@echo "Starting stacks from archive at Epoch 3.2"
	@echo "  CHAINSTATE_DIR: $(CHAINSTATE_DIR)"
	@echo "  CHAINSTATE_ARCHIVE: $(CHAINSTATE_ARCHIVE)"
	@echo "  DOCKER_NETWORK: $(DOCKER_NETWORK)"
	echo "$(CHAINSTATE_DIR)" > .current-chainstate-dir
	docker compose -f docker/docker-compose.yml --profile default up -d

down:
	@echo "Shutting down network"
	$(eval ACTIVE_CHAINSTATE_DIR=$(shell cat .current-chainstate-dir))
	docker compose -f docker/docker-compose.yml --profile default down
	rm -f .current-chainstate-dir

up-genesis: check-network-running build
	@echo "Starting stacks from genesis block"
	@echo "  CHAINSTATE_DIR: $(PWD)/docker/chainstate/genesis"
	@echo "  PAUSE_HEIGHT: $(PAUSE_HEIGHT)"
	sudo rm -rf $(PWD)/docker/chainstate/genesis
	CHAINSTATE_DIR=$(PWD)/docker/chainstate/genesis docker compose -f docker/docker-compose.yml --profile default up -d
	echo "$(PWD)/docker/chainstate/genesis" > .current-chainstate-dir

down-genesis: down

build:
	COMPOSE_BAKE=true PWD=$(PWD) docker compose -f docker/docker-compose.yml --profile default build

backup-logs:
	@if [ -f .current-chainstate-dir ]; then \
		ACTIVE_CHAINSTATE_DIR=$$(cat .current-chainstate-dir); \
		echo "Backing up logs to $$ACTIVE_CHAINSTATE_DIR"; \
		for service in $(SERVICES); do \
			if echo "$$ACTIVE_CHAINSTATE_DIR" | grep -q "/genesis$$"; then \
				sudo bash -c "docker logs -t $$service > $$ACTIVE_CHAINSTATE_DIR/$$service.log 2>&1"; \
			else \
				docker logs -t $$service > $$ACTIVE_CHAINSTATE_DIR/$$service.log 2>&1; \
			fi; \
		done; \
	fi

snapshot: down
	@echo "ACTIVE_CHAINSTATE_DIR: $(ACTIVE_CHAINSTATE_DIR)"
	cd $(ACTIVE_CHAINSTATE_DIR); sudo tar --zstd -cf $(CHAINSTATE_ARCHIVE) *; cd $(PWD)

pause:
	docker compose -f docker/docker-compose.yml --profile=default pause "$(Arguments)"

resume:
	docker compose -f docker/docker-compose.yml --profile=default unpause "$(Arguments)"

# pause:
# 	@echo "pause services"
# 	docker-compose -f docker/docker-compose.yml pause stacks-signer-1 stacks-signer-2 stacks-signer-3 stacks-miner-1 stacks-miner-2 stacks-miner-3 bitcoin bitcoin-miner postgres stacks-api monitor stacker tx-broadcaster

.PHONY: check-network-running up down up-genesis down-genesis build backup-logs snapshot pause resume
.ONESHELL: all-in-one-shell


	# docker inspect --format='{{.LogPath}}' stacks-signer-1
	# # symlink to the chainstate_dir
