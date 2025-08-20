COMMANDS := sudo tar zstd getent stress
$(foreach bin,$(COMMANDS),\
	$(if $(shell command -v $(bin) 2> /dev/null),$(info),$(error Missing required dependency: `$(bin)`)))

ifeq (log,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
ifeq (pause,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
ifeq (unpause,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
ifeq (stop,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
ifeq (start,$(firstword $(MAKECMDGOALS)))
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
CORES ?= $(shell cat /proc/cpuinfo | grep processor | wc -l)
TIMEOUT ?= 120
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

up: check-network-running | build $(CHAINSTATE_DIR)
	@echo "Starting stacks from archive at Epoch 3.2"
	@echo "  CHAINSTATE_DIR: $(CHAINSTATE_DIR)"
	@echo "  CHAINSTATE_ARCHIVE: $(CHAINSTATE_ARCHIVE)"
	@echo "  DOCKER_NETWORK: $(DOCKER_NETWORK)"
	echo "$(CHAINSTATE_DIR)" > .current-chainstate-dir
	docker compose -f docker/docker-compose.yml --profile default up -d

down: current-chainstate-dir
	@echo "Shutting down network"
	$(eval ACTIVE_CHAINSTATE_DIR=$(shell cat .current-chainstate-dir))
	docker compose -f docker/docker-compose.yml --profile default down
	@if [ -f .current-chainstate-dir ]; then \
	    rm -f .current-chainstate-dir
	fi

up-genesis: check-network-running | build
	@echo "Starting stacks from genesis block"
	@echo "  CHAINSTATE_DIR: $(PWD)/docker/chainstate/genesis"
	@echo "  PAUSE_HEIGHT: $(PAUSE_HEIGHT)"
	@if [ -d $(PWD)/docker/chainstate/genesis ]; then \
       sudo rm -rf $(PWD)/docker/chainstate/genesis
	fi
	CHAINSTATE_DIR=$(PWD)/docker/chainstate/genesis docker compose -f docker/docker-compose.yml --profile default up -d
	echo "$(PWD)/docker/chainstate/genesis" > .current-chainstate-dir



down-genesis: down

build:
	COMPOSE_BAKE=true PWD=$(PWD) docker compose -f docker/docker-compose.yml --profile default build

log:
	docker compose -f docker/docker-compose.yml --profile=default logs -t --no-log-prefix $(Arguments) -f

log-all:
	docker compose -f docker/docker-compose.yml --profile=default logs -t -f


# backup service logs to $ACTIVE_CHAINSTATE_DIR/logs/<service-name>.log
backup-logs:
	@if [ -f .current-chainstate-dir ]; then \
		ACTIVE_CHAINSTATE_DIR=$$(cat .current-chainstate-dir); \
		if  [ ! -d "$$ACTIVE_CHAINSTATE_DIR" ]; then \
			echo "Chainstate Dir ($$ACTIVE_CHAINSTATE_DIR) not found";\
			exit 1; \
		fi; \
		if  [ ! -d "$$ACTIVE_CHAINSTATE_DIR/logs" ]; then \
			mkdir -p $$ACTIVE_CHAINSTATE_DIR/logs;\
		fi; \
		echo "Backing up logs to $$ACTIVE_CHAINSTATE_DIR/logs"; \
		for service in $(SERVICES); do \
			if echo "$$ACTIVE_CHAINSTATE_DIR" | grep -q "/genesis$$"; then \
				sudo bash -c "docker logs -t $$service > $$ACTIVE_CHAINSTATE_DIR/logs/$$service.log 2>&1"; \
			else \
				docker logs -t $$service > $$ACTIVE_CHAINSTATE_DIR/logs/$$service.log 2>&1; \
			fi; \
		done; \
	fi

current-chainstate-dir:
	$(eval ACTIVE_CHAINSTATE_DIR=$(shell cat .current-chainstate-dir))

snapshot: current-chainstate-dir down
	@echo "Creating chainstate snapshot from $(ACTIVE_CHAINSTATE_DIR)"
	cd $(ACTIVE_CHAINSTATE_DIR); sudo tar --zstd -cf $(CHAINSTATE_ARCHIVE) *; cd $(PWD)

pause:
	@echo "Pausing all services"
	docker compose -f docker/docker-compose.yml --profile=default pause $(SERVICES)

unpause:
	@echo "Unpausing all services"
	docker compose -f docker/docker-compose.yml --profile=default unpause $(SERVICES)

stop: current-chainstate-dir
	@echo "Stopping service $(Arguments)"
	docker compose -f docker/docker-compose.yml --profile=default down "$(Arguments)"

start: current-chainstate-dir
	@echo "Starting service $(Arguments)"
	CHAINSTATE_DIR=$(ACTIVE_CHAINSTATE_DIR) docker compose -f docker/docker-compose.yml --profile=default up -d "$(Arguments)"

stress:
	@echo "CORES: $(CORES)"
	@echo "TIMEOUT: $(TIMEOUT)"
	stress --cpu $(CORES) --timeout $(TIMEOUT)

x: | build up

.PHONY: check-network-running up down up-genesis down-genesis build backup-logs current-chainstate-dir snapshot pause unpause stop start stress x
.ONESHELL: all-in-one-shell
