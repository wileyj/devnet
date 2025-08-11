ifeq (log,$(firstword $(MAKECMDGOALS)))
	Arguments := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
endif
export UID := $(shell getent passwd $$(whoami) | cut -d":" -f 3)
export GID := $(shell getent passwd $$(whoami) | cut -d":" -f 4)
EPOCH := $(shell date +%s)
PWD = $(shell pwd)
CHAINSTATE_ARCHIVE ?= $(PWD)/docker/chainstate.tar.zstd
export CHAINSTATE_DIR ?= $(PWD)/docker/chainstate/$(EPOCH)
export DOCKER_NETWORK ?= stacks
SERVICES := $(shell CHAINSTATE_DIR="" docker compose -f docker/docker-compose.yml --profile=default config --services)


$(CHAINSTATE_DIR):
	@echo "Creating Chainstate Dir ($(CHAINSTATE_DIR))"
	mkdir -p $@
	if [ -f "$(CHAINSTATE_ARCHIVE)" -a "$(MAKECMDGOALS)" = "up" ]; then
		sudo tar --same-owner -xf $(CHAINSTATE_ARCHIVE) -C $(CHAINSTATE_DIR) || false
	fi

up: down build | $(CHAINSTATE_DIR)
	@echo "Starting stacks from archive at Epoch 3.2"
	@echo "  CHAINSTATE_DIR: $(CHAINSTATE_DIR)"
	@echo "  CHAINSTATE_ARCHIVE: $(CHAINSTATE_ARCHIVE)"
	@echo "  DOCKER_NETWORK: $(DOCKER_NETWORK)"
	docker compose -f docker/docker-compose.yml --profile default up -d
	@$(MAKE) link-logs # link docker json-logs to CHAINSTATE_DIR

down:
	@echo "Shutting down network"
	docker compose -f docker/docker-compose.yml --profile default down -v

up-genesis: down build
	@echo "Starting stacks from genesis block"
	@echo "  CHAINSTATE_DIR: $(PWD)/docker/chainstate/genesis"
	CHAINSTATE_DIR=$(PWD)/docker/chainstate/genesis docker compose -f docker/docker-compose.yml --profile default up -d
	@$(MAKE) link-logs # link docker json-logs to CHAINSTATE_DIR

down-genesis: down

log:
	docker compose -f docker/docker-compose.yml --profile=default logs -t --no-log-prefix $(Arguments)

log-all:
	docker compose -f docker/docker-compose.yml --profile=default logs -t -f

build:
	COMPOSE_BAKE=true PWD=$(PWD) docker compose -f docker/docker-compose.yml --profile default build


link-logs:  # using CHAINSTATE_DIR, symlink the docker json log to the dynamic dir based on service name
	@$(foreach SERVICE,$(SERVICES), \
	    $(eval LOG=$(shell docker inspect --format='{{.LogPath}}' $(SERVICE))) \
		sudo ln -s "$(LOG)" "$(CHAINSTATE_DIR)/$(SERVICE).log" ; \
    )

.PHONY: up down up-genesis down-genesis log log-all
.ONESHELL: all-in-one-shell
