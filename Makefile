COMMANDS := sudo tar zstd getent stress
$(foreach bin,$(COMMANDS),\
	$(if $(shell command -v $(bin) 2> /dev/null),$(info),$(error Missing required dependency: `$(bin)`)))

TARGET := $(firstword $(MAKECMDGOALS))
PARAMS := $(filter-out $(TARGET),$(MAKECMDGOALS))
ifeq ($(TARGET),up-genesis)
	export CHAINSTATE_DIR := $(PWD)/docker/chainstate/genesis
endif
ifeq ($(TARGET),genesis)
	export CHAINSTATE_DIR := $(PWD)/docker/chainstate/genesis
endif


## UID and GID are not currently used, but will be in the near future
export UID := $(shell getent passwd $$(whoami) | cut -d":" -f 3)
export GID := $(shell getent passwd $$(whoami) | cut -d":" -f 4)
EPOCH := $(shell date +%s)
PWD = $(shell pwd)
# Set a unique project name (used for checking if the network is running)
PROJECT ?= devnet
CHAINSTATE_ARCHIVE ?= $(PWD)/docker/chainstate.tar.zstd
export CHAINSTATE_DIR ?= $(PWD)/docker/chainstate/$(EPOCH)
export DOCKER_NETWORK ?= stacks
SERVICES := $(shell CHAINSTATE_DIR="" docker compose -f docker/docker-compose.yml --profile=default config --services)
PAUSE_HEIGHT ?= 999999999999
# Used for the stress testing target. modifies how much cpu to consume for how long
STRESS_CORES ?= $(shell cat /proc/cpuinfo | grep processor | wc -l)
STRESS_TIMEOUT ?= 120

# Create the chainstate dir and extract an archive to it when the "up" target is used
$(CHAINSTATE_DIR): /usr/bin/tar /usr/bin/zstd
	@if  [ ! -d "$(CHAINSTATE_DIR)" ]; then \
		@mkdir -p $(CHAINSTATE_DIR)
		@if [ "$(TARGET)" = "up" ]; then
			if [ -f "$(CHAINSTATE_ARCHIVE)" ]; then
				sudo tar --same-owner -xf $(CHAINSTATE_ARCHIVE) -C $(CHAINSTATE_DIR) || exit 1
			else
				@echo "Chainstate archive ($(CHAINSTATE_ARCHIVE)) not found. Exiting"
				rm -rf $(CHAINSTATE_DIR)
				exit 1
			fi
		fi
	fi

# Boot the network from the local chainstate archive
up: check-not-running | $(CHAINSTATE_DIR)
# up: check-not-running | build $(CHAINSTATE_DIR)
	@echo "Starting $(PROJECT) network from chainstate archive"
	@echo "  Chainstate Dir: $(CHAINSTATE_DIR)"
	@echo "  Chainstate Archive: $(CHAINSTATE_ARCHIVE)"
	echo "$(CHAINSTATE_DIR)" > .current-chainstate-dir
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) up -d

# Run the network from genesis
genesis: check-not-running | build $(CHAINSTATE_DIR) /usr/bin/sudo
	@echo "Starting $(PROJECT) network from genesis"
	@if  [ -d "$(CHAINSTATE_DIR)/logs" ]; then \
		echo "    Removing existing genesis chainstate dir: $(CHAINSTATE_DIR)"; \
		rm -rf $(CHAINSTATE_DIR)/logs; \
	fi
	@echo "  Chainstate Dir: $(CHAINSTATE_DIR)"
	mkdir -p "$(CHAINSTATE_DIR)"
	echo "$(CHAINSTATE_DIR)" > .current-chainstate-dir
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) up -d

# secondary name to run genesis network
up-genesis: genesis
# secondary name to bring down genesis network
down-genesis: down

# Shut down the network (chainstate and logs will be preserved, but not logs)
down: backup-logs current-chainstate-dir
	@echo "Shutting down $(PROJECT) network"
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) down
	@if [ -f .current-chainstate-dir ]; then \
		rm -f .current-chainstate-dir
	fi

# if the network is in a weird state - this target will force kill (bypassing error checks)
down-force:
	@echo "Force Shutting down $(PROJECT) network"
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) down
	@if [ -f .current-chainstate-dir ]; then \
		rm -f .current-chainstate-dir
	fi

# Build the images with a cache if present
build: check-not-running
	COMPOSE_BAKE=true PWD=$(PWD) docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) build

# Build the images without a cache (default uses cache)
build-no-cache: check-not-running
	COMPOSE_BAKE=true PWD=$(PWD) docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) build --no-cache

# Stream specified service logs to STDOUT. does not validate if PARAMS is supplied
log: current-chainstate-dir
	@echo "Logs for service $(PARAMS)"
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) logs -t --no-log-prefix $(PARAMS) -f

# Stream all services logs to STDOUT
log-all: current-chainstate-dir
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) logs -t -f

# Backup all service logs to $ACTIVE_CHAINSTATE_DIR/logs/<service-name>.log
backup-logs: current-chainstate-dir /usr/bin/sudo
	@if [ -f .current-chainstate-dir ]; then \
		$(eval ACTIVE_CHAINSTATE_DIR=$(shell cat .current-chainstate-dir))
		if  [ ! -d "$(ACTIVE_CHAINSTATE_DIR)" ]; then \
			echo "Chainstate Dir ($(ACTIVE_CHAINSTATE_DIR)) not found";\
			exit 1; \
		fi; \
		if  [ ! -d "$(ACTIVE_CHAINSTATE_DIR)/logs" ]; then \
			mkdir -p $(ACTIVE_CHAINSTATE_DIR)/logs;\
		fi; \
		echo "Backing up logs to $(ACTIVE_CHAINSTATE_DIR)/logs"; \
		for service in $(SERVICES); do \
			docker logs -t $$service > $(ACTIVE_CHAINSTATE_DIR)/logs/$$service.log 2>&1; \
		done; \
	fi

# set env var of what the statically defined chainstate dir is
current-chainstate-dir: | check-running
	$(eval ACTIVE_CHAINSTATE_DIR=$(shell cat .current-chainstate-dir))

# replace the existing chainstate archive. will be used with target `up`
snapshot: current-chainstate-dir down
	@echo "Creating $(PROJECT) chainstate snapshot from $(ACTIVE_CHAINSTATE_DIR)"
	@if  [ -d "$(ACTIVE_CHAINSTATE_DIR)/logs" ]; then \
		rm -rf $(ACTIVE_CHAINSTATE_DIR)/logs; \
	fi
	@echo "Creating snapshot: $(CHAINSTATE_ARCHIVE)"
	@echo "cd $(ACTIVE_CHAINSTATE_DIR); sudo tar --zstd -cf $(CHAINSTATE_ARCHIVE) *; cd $(PWD)"
	cd $(ACTIVE_CHAINSTATE_DIR); sudo tar --zstd -cf $(CHAINSTATE_ARCHIVE) *; cd $(PWD)

# pause all services in the network (netork is down,  but recoverably with target 'unpause')
pause:
	@echo "Pausing all services"
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) pause $(SERVICES)

# unpause all services in the network (only used after first using target 'pause')
unpause:
	@echo "Unpausing all services"
	docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) unpause $(SERVICES)

# stop an individual service
stop: check-params current-chainstate-dir | check-running
	@echo "Killing service $(PARAMS)"
	@echo "  Chainstate Dir: $(ACTIVE_CHAINSTATE_DIR)"
	@echo "  Target: $(TARGET)"
	@echo "  Params: $(PARAMS)"
	CHAINSTATE_DIR=$(ACTIVE_CHAINSTATE_DIR) docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) down $(PARAMS)

# start an individual service
start: check-params current-chainstate-dir | check-running
	@echo "Resuming service $(PARAMS)"
	@echo "  Chainstate Dir: $(ACTIVE_CHAINSTATE_DIR)"
	@echo "  Target: $(TARGET)"
	@echo "  Params: $(PARAMS)"
	CHAINSTATE_DIR=$(ACTIVE_CHAINSTATE_DIR) docker compose -f docker/docker-compose.yml --profile default -p $(PROJECT) up -d $(PARAMS)

# restart a service with a defined  servicename/duration. called script will validate PARAMS
#   if no duration is provided, default of 30s shall be used
restart: check-params | check-running
	@echo "Restarting service"
	@echo "  Params: $(PARAMS)"
	./docker/tests/restart-container.sh $(PARAMS)

# use 'stress' binary to consume defined cpu over a specified time
stress:
	@echo "Stressing system CPU $(PARAMS)"
	@echo "  Cores: $(STRESS_CORES)"
	@echo "  Timeout: $(STRESS_TIMEOUT)"
	stress --cpu $(STRESS_CORES) --timeout $(STRESS_TIMEOUT)

# run the test script to verify the services are all load and operating as expected
test:
	./docker/tests/devnet-liveness.sh

# run the chain monitor script (loops and curls /v2/info, parsing the output to show current heights of miners)
monitor:
	./docker/tests/chain-monitor.sh

# if the network is already running, we need to exit (ex: trying to start the network when it's already running)
check-not-running:
	@if test `docker compose ls --filter name=$(PROJECT) -q`; then \
		echo ""; \
		echo "WARNING: Network appears to be running or was not properly shut down."; \
		echo "Current chainstate directory: $$(cat .current-chainstate-dir)"; \
		echo ""; \
		echo "To backup logs first: make backup-logs"; \
		echo "To shut down:         make down"; \
		echo ""; \
		exit 1; \
	fi

# if the network is not running, we need to exit (ex: trying to restart a container)
check-running:
	@if test ! `docker compose ls --filter name=$(PROJECT) -q`; then \
		echo "Network not running. exiting"; \
		exit 1; \
	fi

# for targets that need an arg, check that *something* is provided. it not, exit
check-params: | check-running
	@if [ ! "$(PARAMS)" ]; then \
		echo "No service defined. Exiting"; \
		exit 1; \
	fi

# force stop and remove any existing chainstates (leaving all docker images/layers)
clean: down-force
	sudo rm -rf ./docker/chainstate/*


.PHONY: up genesis up-genesis down-genesis down down-force build build-no-cache log log-all backup-logs current-chainstate-dir snapshot pause unpause stop start restart stress test monitor check-not-running check-running check-params clean
.ONESHELL: all-in-one-shell
