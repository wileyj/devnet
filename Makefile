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


$(CHAINSTATE_DIR):
	@echo "Creating Chainstate Dir ($(CHAINSTATE_DIR))"
	mkdir -p $@
	if [ -f "$(CHAINSTATE_ARCHIVE)" -a "$(MAKECMDGOALS)" = "up" ]; then
		sudo tar --same-owner -xf $(CHAINSTATE_ARCHIVE) -C $(CHAINSTATE_DIR) || false
	fi

up: | $(CHAINSTATE_DIR)
	@echo "Starting stacks from archive at Epoch 3.2"
	@echo "  CHAINSTATE_DIR: $(CHAINSTATE_DIR)"
	@echo "  CHAINSTATE_ARCHIVE: $(CHAINSTATE_ARCHIVE)"
	@echo "  DOCKER_NETWORK: $(DOCKER_NETWORK)"
	docker compose -f docker/docker-compose.yml --profile default up -d

down:
	@echo "Shutting down network"
# export the logs to the chainstate_dir on `down`
	docker compose -f docker/docker-compose.yml --profile default down -v

up-genesis:
	@echo "Starting stacks from genesis block"
	@echo "  CHAINSTATE_DIR: $(PWD)/docker/chainstate/genesis"
	CHAINSTATE_DIR=$(PWD)/docker/chainstate/genesis docker compose -f docker/docker-compose.yml --profile default up -d

down-genesis: down

log:
	docker compose -f docker/docker-compose.yml --profile=default logs -t --no-log-prefix "$(Arguments)" -f

log-all:
	docker compose -f docker/docker-compose.yml --profile=default logs -t -f

.PHONY: up down up-genesis down-genesis log log-all
.ONESHELL: all-in-one-shell

# .PHONY: up down extract-chainstate up-genesis down-genesis log log-all

# # up-bitcoin:
# # 		# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default up -d
# # 		# UID=$(UID) GID=$(GID) docker compose -f docker/docker-compose.yml --profile default up -d
# # 		#sudo sudo rm -rf docker/persistent/*
# # 		docker compose -f docker/docker-compose.yml --profile default up -d
# # down-bitcoin:
# # 		# DOCKER_NETWORK=stacks docker compose -f docker/docker-compose.yml --profile default down -t 0 -v
# # 		# docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v
# # 		docker compose -f docker/docker-compose.yml --profile default down

# # # Network with 3 miners/signers|2 followre|seed node|api
# # up-follower:
# # 	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default up -d
# # down-follower:
# # 	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default down -t 0 -v

# # # Network with 5 miners/signers|seed node|api
# # up-five:
# # 	docker compose -f docker/docker-compose.yml --profile --profile five-miners default up -d
# # down-five:
# # 	docker compose -f docker/docker-compose.yml --profile --profile five-miners default down -t 0 -v
# # # Network with 5 miners/signers|2 followers|seed node|api
# # up-five-follower:
# # 	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower up -d
# # down-five-follower:
# # 	STACKS_FOLLOWER_REPLICAS=2 docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower down -t 0 -v

# # # build images locally
# # build:
# # 	docker compose -f docker/docker-compose.yml --profile default build --progress=plain --no-cache
# # build-five:
# # 	docker compose -f docker/docker-compose.yml --profile --profile five-miners default build --progress=plain --no-cache
# # build-five-follower:
# # 	docker compose -f docker/docker-compose.yml --profile default --profile five-miners --profile follower build --progress --no-cache

# # x: # down && build && up
# # 	docker compose -f docker/docker-compose-three-miners.yml --profile default down -t 0 -v
# # 	docker compose -f docker/docker-compose-three-miners.yml --profile default build
# # 	docker compose -f docker/docker-compose-three-miners.yml --profile default up -d

# # .PHONY: up down build x
